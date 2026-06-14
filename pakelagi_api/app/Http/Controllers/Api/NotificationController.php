<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = \App\Models\Notification::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $notifications
        ]);
    }

    public function markAsRead(Request $request, $id)
    {
        $notification = \App\Models\Notification::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if ($notification) {
            $notification->update(['is_read' => true]);
        }

        return response()->json([
            'status' => 'success'
        ]);
    }

    public function unreadCount(Request $request)
    {
        $userId = $request->user()->id;
        
        $totalUnread = \App\Models\Notification::where('user_id', $userId)
            ->where('is_read', false)
            ->count();
            
        $orderUnread = \App\Models\Notification::where('user_id', $userId)
            ->where('is_read', false)
            ->whereIn('type', ['order', 'order_update', 'order_cancelled'])
            ->count();

        return response()->json([
            'status' => 'success',
            'data' => [
                'total_unread' => $totalUnread,
                'order_unread' => $orderUnread,
            ]
        ]);
    }
}
