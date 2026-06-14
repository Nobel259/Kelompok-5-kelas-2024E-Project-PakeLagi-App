<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\SearchController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\AddressController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\CartController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\BankController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // Profile Routes
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::post('/profile', [ProfileController::class, 'update']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);
    Route::post('/delete-account', [AuthController::class, 'deleteAccount']);
    Route::post('/change-email', [AuthController::class, 'changeEmail']);

    // Search Routes
    Route::get('/search', [SearchController::class, 'index']);
    Route::post('/search', [SearchController::class, 'store']);
    Route::delete('/search/{id}', [SearchController::class, 'destroy']);

    // Notification Routes
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);

    // Address Routes
    Route::get('/addresses', [AddressController::class, 'index']);
    Route::post('/addresses', [AddressController::class, 'store']);
    Route::delete('/addresses/{id}', [AddressController::class, 'destroy']);

    // Bank Routes
    Route::get('/banks', [BankController::class, 'index']);
    Route::post('/banks', [BankController::class, 'store']);
    Route::delete('/banks/{id}', [BankController::class, 'destroy']);

    // Product Routes
    Route::get('/products', [ProductController::class, 'index']);
    Route::post('/products', [ProductController::class, 'store']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);

    // Favorite Routes
    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites', [FavoriteController::class, 'store']);
    Route::get('/favorites/check', [FavoriteController::class, 'check']);


    // Order Routes
    Route::get('/orders/sold', [OrderController::class, 'sold']);
    Route::get('/orders/bought', [OrderController::class, 'bought']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);
    Route::post('/orders/{id}/payment', [OrderController::class, 'uploadPayment']);
    Route::post('/orders/{id}/confirm', [OrderController::class, 'confirmPayment']);
    Route::post('/orders/{id}/shipping', [OrderController::class, 'updateShipping']);
    Route::post('/orders/{id}/complete', [OrderController::class, 'complete']);
    Route::post('/orders/{id}/cancel', [OrderController::class, 'cancel']);

    // User Profile (view other users)
    Route::get('/users/{id}/profile', function ($id) {
        $user = \App\Models\User::with('bankAccounts')->findOrFail($id);
        $productsQuery = \App\Models\Product::where('user_id', $id)
            ->where('is_sold', false)
            ->with(['address'])
            ->latest();

        $authUser = auth('sanctum')->user();
        if (!$authUser || $authUser->id != $id) {
            if ($user->is_vacation) {
                $productsQuery->whereRaw('1 = 0');
            }
        }
        
        $products = $productsQuery->get();
        
        $userData = $user->only(['id', 'full_name', 'username', 'profile_picture_url', 'bio', 'created_at', 'bank_name', 'bank_account_number', 'bank_account_name', 'is_vacation']);
        $userData['bank_accounts'] = $user->bankAccounts;
        
        return response()->json([
            'user' => $userData,
            'products' => $products,
        ]);
    });

    // Vacation Mode
    Route::post('/user/vacation', function (Request $request) {
        $user = $request->user();
        $user->is_vacation = !$user->is_vacation;
        $user->save();
        return response()->json([
            'message' => $user->is_vacation ? 'Mode liburan diaktifkan' : 'Mode liburan dinonaktifkan',
            'is_vacation' => $user->is_vacation,
        ]);
    });

    // Chat Routes
    Route::get('/chats/unread-count', [ChatController::class, 'unreadTotal']);
    Route::get('/chats', [ChatController::class, 'index']);
    Route::get('/chats/users', [ChatController::class, 'getUsers']);
    Route::get('/chats/{other_user_id}', [ChatController::class, 'show']);
    Route::post('/chats', [ChatController::class, 'store']);

    // Cart Routes
    Route::get('/cart', [CartController::class, 'index']);
    Route::post('/cart', [CartController::class, 'store']);
    Route::delete('/cart/{id}', [CartController::class, 'destroy']);
    Route::post('/cart/checkout', [CartController::class, 'checkoutSeller']);

    // Review Routes
    Route::get('/reviews', [ReviewController::class, 'index']);
    Route::post('/reviews', [ReviewController::class, 'store']);
});
