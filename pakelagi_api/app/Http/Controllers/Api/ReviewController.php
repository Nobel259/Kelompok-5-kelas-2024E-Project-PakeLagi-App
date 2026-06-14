<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\Product;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function index(Request $request)
    {
        $query = Review::with(['reviewer', 'product.user', 'product.address', 'seller']);

        if ($request->has('seller_id')) {
            $query->where('seller_id', $request->seller_id);
        } elseif ($request->has('reviewer_id')) {
            $query->where('reviewer_id', $request->reviewer_id);
        } else {
            return response()->json([
                'status' => 'error',
                'message' => 'Harap berikan seller_id atau reviewer_id'
            ], 400);
        }

        $reviews = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $reviews
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'seller_id' => 'required|exists:users,id',
            'product_id' => 'required|exists:products,id',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string',
        ]);

        $reviewerId = auth()->id();

        // Avoid self-reviewing
        if ($reviewerId == $request->seller_id) {
            return response()->json([
                'status' => 'error',
                'message' => 'Anda tidak dapat mengulas toko Anda sendiri.'
            ], 422);
        }

        $review = Review::create([
            'reviewer_id' => $reviewerId,
            'seller_id' => $request->seller_id,
            'product_id' => $request->product_id,
            'rating' => $request->rating,
            'comment' => $request->comment,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Ulasan berhasil ditambahkan.',
            'data' => $review
        ], 201);
    }
}
