<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Notification;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    private function expireOrders()
    {
        $expiredOrders = Order::where('status', 'pending_payment')
            ->where('created_at', '<', now()->subHours(24))
            ->get();
            
        foreach ($expiredOrders as $order) {
            $order->update(['status' => 'cancelled']);
            if ($order->product) {
                $order->product->update(['is_sold' => false]);
            }
            
            // Notify buyer
            Notification::create([
                'user_id' => $order->buyer_id,
                'title' => 'Pesanan Dibatalkan',
                'body' => 'Pesanan Anda otomatis dibatalkan karena tidak ada pembayaran dalam 1x24 jam.',
                'type' => 'order_cancelled',
            ]);
            
            // Notify seller
            Notification::create([
                'user_id' => $order->seller_id,
                'title' => 'Pesanan Dibatalkan',
                'body' => 'Pesanan dari pembeli otomatis dibatalkan karena tidak dibayar dalam 1x24 jam.',
                'type' => 'order_cancelled',
            ]);
        }
    }

    public function sold(Request $request)
    {
        $this->expireOrders();
        
        $orders = Order::where('seller_id', $request->user()->id)
            ->with(['product.user', 'product.address', 'buyer'])
            ->latest()
            ->get();

        return response()->json(['data' => $orders]);
    }

    public function bought(Request $request)
    {
        $this->expireOrders();
        
        $orders = Order::where('buyer_id', $request->user()->id)
            ->with(['product.user', 'product.address', 'seller'])
            ->latest()
            ->get();

        return response()->json(['data' => $orders]);
    }

    public function show(Request $request, $id)
    {
        $order = Order::with(['product.user', 'product.address', 'buyer', 'seller'])
            ->where(function ($q) use ($request) {
                $q->where('buyer_id', $request->user()->id)
                  ->orWhere('seller_id', $request->user()->id);
            })
            ->findOrFail($id);

        return response()->json(['data' => $order]);
    }

    public function uploadPayment(Request $request, $id)
    {
        $order = Order::where('buyer_id', $request->user()->id)->findOrFail($id);

        if (!in_array($order->status, ['pending_payment'])) {
            return response()->json(['message' => 'Bukti pembayaran sudah diunggah sebelumnya.'], 422);
        }

        $request->validate([
            'payment_proof' => 'required|image|mimes:jpeg,png,jpg|max:10240',
        ]);

        $uploadPath = public_path('uploads/payments');
        if (!file_exists($uploadPath)) {
            mkdir($uploadPath, 0755, true);
        }

        $file = $request->file('payment_proof');
        $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
        $file->move($uploadPath, $filename);

        $order->update([
            'payment_proof' => '/uploads/payments/' . $filename,
            'status' => 'payment_uploaded',
        ]);

        Notification::create([
            'user_id' => $order->seller_id,
            'title' => 'Bukti Pembayaran Diunggah',
            'body' => 'Pembeli telah mengunggah bukti pembayaran untuk pesanan Anda.',
            'type' => 'order_update',
        ]);

        return response()->json(['message' => 'Bukti pembayaran berhasil diunggah.', 'data' => $order]);
    }

    public function confirmPayment(Request $request, $id)
    {
        $order = Order::where('seller_id', $request->user()->id)->findOrFail($id);

        if ($order->status !== 'payment_uploaded') {
            return response()->json(['message' => 'Status pesanan tidak valid untuk konfirmasi.'], 422);
        }

        $order->update(['status' => 'payment_confirmed']);

        Notification::create([
            'user_id' => $order->buyer_id,
            'title' => 'Pembayaran Dikonfirmasi',
            'body' => 'Penjual telah mengonfirmasi pembayaran Anda. Pesanan sedang disiapkan.',
            'type' => 'order_update',
        ]);

        return response()->json(['message' => 'Pembayaran dikonfirmasi.', 'data' => $order]);
    }

    public function updateShipping(Request $request, $id)
    {
        $order = Order::where('seller_id', $request->user()->id)->findOrFail($id);

        if (!in_array($order->status, ['payment_confirmed', 'shipped'])) {
            return response()->json(['message' => 'Konfirmasi pembayaran terlebih dahulu.'], 422);
        }

        $request->validate([
            'shipping_code' => 'required|string|max:255',
            'shipping_courier' => 'nullable|string|max:255',
        ]);

        $order->update([
            'shipping_code' => $request->shipping_code,
            'shipping_courier' => $request->shipping_courier,
            'status' => 'shipped',
        ]);

        Notification::create([
            'user_id' => $order->buyer_id,
            'title' => 'Pesanan Dikirim',
            'body' => 'Pesanan Anda telah dikirim dengan no resi: ' . $request->shipping_code,
            'type' => 'order_update',
        ]);

        return response()->json(['message' => 'Kode pengiriman berhasil diperbarui.', 'data' => $order]);
    }

    public function complete(Request $request, $id)
    {
        $order = Order::where('buyer_id', $request->user()->id)->findOrFail($id);

        if ($order->status !== 'shipped') {
            return response()->json(['message' => 'Pesanan belum dikirim.'], 422);
        }

        $order->update(['status' => 'completed']);

        Notification::create([
            'user_id' => $order->seller_id,
            'title' => 'Pesanan Selesai',
            'body' => 'Pembeli telah menerima pesanan. Transaksi telah selesai.',
            'type' => 'order_update',
        ]);

        return response()->json(['message' => 'Pesanan selesai.', 'data' => $order]);
    }

    public function cancel(Request $request, $id)
    {
        $userId = $request->user()->id;
        $order = Order::where(function ($q) use ($userId) {
            $q->where('buyer_id', $userId)
              ->orWhere('seller_id', $userId);
        })->findOrFail($id);

        if ($order->status !== 'pending_payment') {
            return response()->json(['message' => 'Hanya pesanan yang menunggu pembayaran yang dapat dibatalkan.'], 422);
        }

        $order->update(['status' => 'cancelled']);
        
        if ($order->product) {
            $order->product->update(['is_sold' => false]);
        }

        $otherUserId = $order->buyer_id == $userId ? $order->seller_id : $order->buyer_id;
        
        Notification::create([
            'user_id' => $otherUserId,
            'title' => 'Pesanan Dibatalkan',
            'body' => 'Pesanan telah dibatalkan.',
            'type' => 'order_cancelled',
        ]);

        return response()->json(['message' => 'Pesanan berhasil dibatalkan.', 'data' => $order]);
    }
}
