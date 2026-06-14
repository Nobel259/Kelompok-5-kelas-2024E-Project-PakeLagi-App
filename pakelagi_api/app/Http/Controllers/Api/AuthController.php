<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
        ]);

        $defaultUsername = explode('@', $request->email)[0];
        // Ensure uniqueness of auto-generated username
        $baseUsername = $defaultUsername;
        $counter = 1;
        while (User::where('username', $defaultUsername)->exists()) {
            $defaultUsername = $baseUsername . $counter;
            $counter++;
        }

        $user = User::create([
            'full_name' => $request->full_name,
            'email' => $request->email,
            'username' => $defaultUsername,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registrasi berhasil',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Email atau kata sandi salah.'
            ], 401);
        }

        // Auto-generate username for old users who logged in and have null username
        if (empty($user->username)) {
            $defaultUsername = explode('@', $user->email)[0];
            $baseUsername = $defaultUsername;
            $counter = 1;
            while (User::where('username', $defaultUsername)->exists()) {
                $defaultUsername = $baseUsername . $counter;
                $counter++;
            }
            $user->username = $defaultUsername;
            $user->save();
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout berhasil'
        ]);
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'old_password' => 'required',
            'new_password' => 'required|min:6',
        ]);

        $user = $request->user();

        if (!Hash::check($request->old_password, $user->password)) {
            return response()->json([
                'message' => 'Kata sandi lama tidak sesuai.'
            ], 422);
        }

        $user->password = Hash::make($request->new_password);
        $user->save();

        return response()->json([
            'message' => 'Kata sandi berhasil diperbarui.'
        ]);
    }

    public function deleteAccount(Request $request)
    {
        $user = $request->user();
        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'message' => 'Akun Anda berhasil dihapus secara permanen.'
        ]);
    }

    public function changeEmail(Request $request)
    {
        $request->validate([
            'email' => 'required|email|unique:users,email,' . $request->user()->id,
        ]);

        $user = $request->user();
        $user->email = $request->email;
        $user->save();

        return response()->json([
            'message' => 'Email berhasil diperbarui.',
            'user' => $user
        ]);
    }
}
