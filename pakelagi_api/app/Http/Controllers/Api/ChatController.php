<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Message;
use App\Models\User;

class ChatController extends Controller
{
    /**
     * Get list of conversations for the authenticated user.
     */
    public function index()
    {
        $authUserId = auth()->id();
        
        $messages = Message::where('sender_id', $authUserId)
            ->orWhere('receiver_id', $authUserId)
            ->orderBy('created_at', 'desc')
            ->get();
            
        $conversations = [];
        $seenUsers = [];
        
        foreach ($messages as $message) {
            $otherUserId = $message->sender_id == $authUserId ? $message->receiver_id : $message->sender_id;
            if (in_array($otherUserId, $seenUsers)) {
                continue;
            }
            $seenUsers[] = $otherUserId;
            
            $otherUser = User::find($otherUserId);
            if ($otherUser) {
                $unreadCount = Message::where('sender_id', $otherUserId)
                    ->where('receiver_id', $authUserId)
                    ->where('is_read', false)
                    ->count();
                    
                $conversations[] = [
                    'id' => $otherUser->id,
                    'full_name' => $otherUser->full_name,
                    'profile_picture_url' => $otherUser->profile_picture_url,
                    'last_message' => $message->message,
                    'last_message_time' => $message->created_at->toIso8601String(),
                    'unread_count' => $unreadCount,
                ];
            }
        }
        
        return response()->json([
            'status' => 'success',
            'data' => $conversations
        ]);
    }

    /**
     * Get all other registered users to start new chat.
     */
    public function getUsers()
    {
        $users = User::where('id', '!=', auth()->id())->get(['id', 'full_name', 'profile_picture_url']);
        
        return response()->json([
            'status' => 'success',
            'data' => $users
        ]);
    }

    /**
     * Get conversation details/message history with a specific user.
     */
    public function show($otherUserId)
    {
        $authUserId = auth()->id();
        
        // Mark all unread messages from this user as read
        Message::where('sender_id', $otherUserId)
            ->where('receiver_id', $authUserId)
            ->where('is_read', false)
            ->update(['is_read' => true]);
            
        $messages = Message::where(function ($q) use ($authUserId, $otherUserId) {
            $q->where('sender_id', $authUserId)->where('receiver_id', $otherUserId);
        })->orWhere(function ($q) use ($authUserId, $otherUserId) {
            $q->where('sender_id', $otherUserId)->where('receiver_id', $authUserId);
        })->orderBy('created_at', 'asc')->get();
        
        return response()->json([
            'status' => 'success',
            'data' => $messages
        ]);
    }

    /**
     * Send a new message.
     */
    public function store(Request $request)
    {
        $request->validate([
            'receiver_id' => 'required|exists:users,id',
            'message' => 'required|string',
        ]);
        
        $message = Message::create([
            'sender_id' => auth()->id(),
            'receiver_id' => $request->receiver_id,
            'message' => $request->message,
            'is_read' => false,
        ]);
        
        return response()->json([
            'status' => 'success',
            'data' => $message
        ], 201);
    }

    /**
     * Get total unread message count for the authenticated user.
     */
    public function unreadTotal()
    {
        $count = Message::where('receiver_id', auth()->id())
            ->where('is_read', false)
            ->count();

        return response()->json([
            'status' => 'success',
            'unread_count' => $count
        ]);
    }
}
