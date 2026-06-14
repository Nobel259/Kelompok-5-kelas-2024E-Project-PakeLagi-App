<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CartItem;
use App\Models\Order;
use App\Models\Product;
use App\Models\Notification;
use Illuminate\Http\Request;

class CartController extends Controller
{
    public function index()
    {
        $userId = auth()->id();
        $cartItems = CartItem::with(['product.user', 'product.address'])
            ->where('user_id', $userId)
            ->whereHas('product.user', function ($query) {
                $query->where('is_vacation', false);
            })
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $cartItems
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
        ]);

        $userId = auth()->id();
        $productId = $request->product_id;

        // Check if the product belongs to the current user
        $product = Product::findOrFail($productId);
        if ($product->user_id == $userId) {
            return response()->json([
                'status' => 'error',
                'message' => 'Anda tidak dapat menambahkan barang Anda sendiri ke keranjang.'
            ], 422);
        }

        // Check if already in cart
        $exists = CartItem::where('user_id', $userId)
            ->where('product_id', $productId)
            ->exists();

        if ($exists) {
            return response()->json([
                'status' => 'error',
                'message' => 'Barang ini sudah ada di keranjang Anda.'
            ], 422);
        }

        $cartItem = CartItem::create([
            'user_id' => $userId,
            'product_id' => $productId,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Barang berhasil ditambahkan ke keranjang.',
            'data' => $cartItem
        ], 201);
    }

    public function destroy($id)
    {
        $cartItem = CartItem::where('user_id', auth()->id())->findOrFail($id);
        $cartItem->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Barang berhasil dihapus dari keranjang.'
        ]);
    }

    public function checkoutSeller(Request $request)
    {
        $request->validate([
            'seller_id' => 'required|exists:users,id',
            'buyer_name' => 'required|string|max:255',
            'buyer_address' => 'required|string',
            'buyer_phone' => 'required|string|max:20',
            'buyer_notes' => 'nullable|string',
        ]);

        $userId = auth()->id();
        $sellerId = $request->seller_id;

        $seller = \App\Models\User::find($sellerId);
        if ($seller && $seller->is_vacation) {
            return response()->json([
                'status' => 'error',
                'message' => 'Penjual sedang dalam mode liburan, Anda tidak dapat melakukan checkout.'
            ], 422);
        }

        // Get all cart items for current user where product belongs to seller_id
        $items = CartItem::where('user_id', $userId)
            ->whereHas('product', function ($query) use ($sellerId) {
                $query->where('user_id', $sellerId);
            })
            ->get();

        if ($items->isEmpty()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Tidak ada barang dari penjual ini di keranjang Anda.'
            ], 422);
        }

        // Create order records and mark products as sold
        foreach ($items as $item) {
            if ($item->product) {
                Order::create([
                    'buyer_id' => $userId,
                    'seller_id' => $sellerId,
                    'product_id' => $item->product->id,
                    'price' => $item->product->price,
                    'status' => 'pending_payment',
                    'buyer_name' => $request->buyer_name,
                    'buyer_address' => $request->buyer_address,
                    'buyer_phone' => $request->buyer_phone,
                    'buyer_notes' => $request->buyer_notes,
                ]);
                $item->product->update(['is_sold' => true]);
            }
            $item->delete();
        }

        Notification::create([
            'user_id' => $sellerId,
            'title' => 'Pesanan Baru!',
            'body' => 'Anda mendapatkan pesanan baru dari ' . $request->buyer_name . '. Silakan periksa halaman Pesanan Anda.',
            'type' => 'order',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Pembelian berhasil! Barang Anda sedang diproses.'
        ]);
    }
}
