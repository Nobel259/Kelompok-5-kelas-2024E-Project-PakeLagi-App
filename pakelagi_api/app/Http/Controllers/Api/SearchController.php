<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Product;
use App\Models\User;
use App\Models\SearchHistory;

class SearchController extends Controller
{
    public function index(Request $request)
    {
        $q = $request->input('q');
        
        // Parse filter arrays
        $brands = $request->input('brands');
        if (is_string($brands)) {
            $brands = json_decode($brands, true) ?? explode(',', $brands);
        }
        $brands = array_filter(array_map('trim', (array) $brands));

        $conditions = $request->input('conditions');
        if (is_string($conditions)) {
            $conditions = json_decode($conditions, true) ?? explode(',', $conditions);
        }
        $conditions = array_filter(array_map('trim', (array) $conditions));

        $sizes = $request->input('sizes');
        if (is_string($sizes)) {
            $sizes = json_decode($sizes, true) ?? explode(',', $sizes);
        }
        $sizes = array_filter(array_map('trim', (array) $sizes));

        $minPrice = $request->input('min_price');
        $maxPrice = $request->input('max_price');

        // Products Query
        $userId = auth('sanctum')->id();
        $productsQuery = Product::with(['user', 'address'])
            ->where(function ($query) use ($userId) {
                $query->whereHas('user', function ($q) {
                    $q->where('is_vacation', false);
                });
                if ($userId) {
                    $query->orWhere('user_id', $userId);
                }
            })
            ->orderBy('created_at', 'desc');

        if ($q) {
            $productsQuery->where(function ($query) use ($q) {
                $query->where('title', 'like', "%{$q}%")
                      ->orWhere('description', 'like', "%{$q}%");
            });
        }

        if (!empty($brands)) {
            $productsQuery->where(function ($query) use ($brands) {
                foreach ($brands as $brand) {
                    $query->orWhereJsonContains('categories', "Brand: $brand")
                          ->orWhere('categories', 'like', "%Brand: $brand%");
                }
            });
        }

        if (!empty($conditions)) {
            $productsQuery->where(function ($query) use ($conditions) {
                foreach ($conditions as $cond) {
                    $query->orWhereJsonContains('categories', "Kondisi: $cond")
                          ->orWhere('categories', 'like', "%Kondisi: $cond%");
                }
            });
        }

        if (!empty($sizes)) {
            $productsQuery->where(function ($query) use ($sizes) {
                foreach ($sizes as $size) {
                    $query->orWhere('categories', 'like', "%({$size})%");
                }
            });
        }

        if ($minPrice !== null && $minPrice !== '') {
            $productsQuery->where('price', '>=', (int) $minPrice);
        }

        if ($maxPrice !== null && $maxPrice !== '') {
            $productsQuery->where('price', '<=', (int) $maxPrice);
        }

        $products = $productsQuery->get();

        // Users Query (exclude self)
        $users = [];
        if ($q) {
            $users = User::where('id', '!=', auth()->id())
                ->where(function ($query) use ($q) {
                    $query->where('full_name', 'like', "%{$q}%")
                          ->orWhere('username', 'like', "%{$q}%");
                })->get();
        }

        // Search History
        $history = SearchHistory::where('user_id', auth()->id())
            ->where('is_deleted', false)
            ->orderBy('updated_at', 'desc')
            ->take(10)
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'products' => $products,
                'users' => $users,
                'history' => $history
            ]
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'keyword' => 'required|string|max:255',
        ]);

        $userId = auth()->id();
        $keyword = trim($request->keyword);

        $history = SearchHistory::where('user_id', $userId)
            ->where('keyword', $keyword)
            ->first();

        if ($history) {
            $history->update([
                'is_deleted' => false,
                'updated_at' => now(),
            ]);
        } else {
            $history = SearchHistory::create([
                'user_id' => $userId,
                'keyword' => $keyword,
                'is_deleted' => false,
            ]);
        }

        return response()->json([
            'status' => 'success',
            'data' => $history
        ]);
    }

    public function destroy($id)
    {
        $history = SearchHistory::where('user_id', auth()->id())->findOrFail($id);
        $history->update(['is_deleted' => true]);

        return response()->json([
            'status' => 'success',
            'message' => 'Search history deleted'
        ]);
    }
}
