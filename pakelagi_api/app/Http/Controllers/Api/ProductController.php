<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $userId = $user ? $user->id : null;

        $products = Product::with(['user', 'address'])
            ->where(function ($query) use ($userId) {
                $query->whereHas('user', function ($q) {
                    $q->where('is_vacation', false);
                });
                
                if ($userId) {
                    $query->orWhere('user_id', $userId);
                }
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $products
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'price' => 'required|numeric',
            'categories' => 'required',
            'address_id' => 'nullable|exists:user_addresses,id',
            'images' => 'required|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,webp|max:10240',
        ]);

        $categories = $request->categories;
        if (is_string($categories)) {
            $categories = json_decode($categories, true) ?? explode(',', $categories);
        }

        $imagePaths = [];
        if ($request->hasFile('images')) {
            $uploadPath = public_path('uploads/products');
            if (!file_exists($uploadPath)) {
                mkdir($uploadPath, 0755, true);
            }
            foreach ($request->file('images') as $file) {
                $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
                $file->move($uploadPath, $filename);
                $imagePaths[] = '/uploads/products/' . $filename;
            }
        }

        $product = Product::create([
            'user_id' => auth()->id(),
            'title' => $request->title,
            'description' => $request->description,
            'price' => $request->price,
            'categories' => $categories,
            'image_paths' => $imagePaths,
            'address_id' => $request->address_id,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Product uploaded successfully',
            'data' => $product
        ], 201);
    }

    public function destroy(Request $request, $id)
    {
        $product = Product::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$product) {
            return response()->json(['message' => 'Produk tidak ditemukan atau bukan milik Anda'], 404);
        }

        // Delete images
        $imagePaths = $product->image_paths ?? [];
        foreach ($imagePaths as $path) {
            $fullPath = public_path(ltrim($path, '/'));
            if (file_exists($fullPath)) {
                unlink($fullPath);
            }
        }

        $product->delete();

        return response()->json(['message' => 'Produk berhasil dihapus']);
    }
}
