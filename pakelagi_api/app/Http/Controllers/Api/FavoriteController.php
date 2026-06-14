<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Favorite;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function index(Request $request)
    {
        $favorites = Favorite::where('user_id', $request->user()->id)
            ->whereHas('product.user', function ($query) {
                $query->where('is_vacation', false);
            })
            ->with(['product.user', 'product.address'])
            ->latest()
            ->get();

        return response()->json(['data' => $favorites]);
    }

    public function store(Request $request)
    {
        $request->validate(['product_id' => 'required|exists:products,id']);

        $user = $request->user();
        $existing = Favorite::where('user_id', $user->id)
            ->where('product_id', $request->product_id)
            ->first();

        if ($existing) {
            $existing->delete();
            return response()->json(['message' => 'Dihapus dari favorit', 'is_favorited' => false]);
        }

        Favorite::create([
            'user_id' => $user->id,
            'product_id' => $request->product_id,
        ]);

        return response()->json(['message' => 'Ditambahkan ke favorit', 'is_favorited' => true], 201);
    }

    public function check(Request $request)
    {
        $request->validate(['product_id' => 'required|exists:products,id']);

        $exists = Favorite::where('user_id', $request->user()->id)
            ->where('product_id', $request->product_id)
            ->exists();

        return response()->json(['is_favorited' => $exists]);
    }
}
