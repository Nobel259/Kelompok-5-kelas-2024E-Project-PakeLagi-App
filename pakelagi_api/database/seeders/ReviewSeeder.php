<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Product;
use App\Models\Review;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class ReviewSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create a few dedicated reviewer users if they don't exist
        $reviewersData = [
            [
                'full_name' => 'Alif Wijaya',
                'username' => 'alifwijaya',
                'email' => 'alif@example.com',
                'password' => Hash::make('password'),
            ],
            [
                'full_name' => 'Budi Santoso',
                'username' => 'budisantoso',
                'email' => 'budi@example.com',
                'password' => Hash::make('password'),
            ],
            [
                'full_name' => 'Siti Aminah',
                'username' => 'sitiaminah',
                'email' => 'siti@example.com',
                'password' => Hash::make('password'),
            ]
        ];

        $reviewerUsers = [];
        foreach ($reviewersData as $data) {
            $user = User::where('email', $data['email'])->first();
            if (!$user) {
                $user = User::create($data);
            }
            $reviewerUsers[] = $user;
        }

        // 2. Get all products
        $products = Product::all();
        
        if ($products->isEmpty()) {
            return;
        }

        $comments = [
            'Barang sampai dengan baik',
            'Barang sampai dengan baik. kualitasnya boleh lah semoga awet',
            'Bahannya sangat premium dan nyaman dipakai, seller juga ramah dan responnya cepat!',
            'Ukuran pas sekali sesuai deskripsi produk. Kondisi sangat terawat, seperti baru.',
            'Sangat puas belanja baju bekas berkualitas di toko ini. Bersih dan wangi!',
            'Pengemasan aman dan pengiriman cepat sekali ke kota saya.',
            'Barang ori, mulus, dan tidak ada cacat tersembunyi. Highly recommended seller!'
        ];

        // 3. Loop through products and seed 2-3 reviews for their owners (sellers)
        foreach ($products as $product) {
            $sellerId = $product->user_id;

            // Pick reviewers that are NOT the seller
            $eligibleReviewers = array_filter($reviewerUsers, function ($rev) use ($sellerId) {
                return $rev->id != $sellerId;
            });

            if (empty($eligibleReviewers)) {
                continue;
            }

            // Seed 2 reviews per product/seller
            $chosenReviewers = array_rand($eligibleReviewers, min(2, count($eligibleReviewers)));
            $chosenReviewers = is_array($chosenReviewers) ? $chosenReviewers : [$chosenReviewers];

            foreach ($chosenReviewers as $key) {
                $reviewer = $eligibleReviewers[$key];

                // Check if review already exists
                $exists = Review::where('reviewer_id', $reviewer->id)
                    ->where('product_id', $product->id)
                    ->exists();

                if (!$exists) {
                    Review::create([
                        'reviewer_id' => $reviewer->id,
                        'seller_id' => $sellerId,
                        'product_id' => $product->id,
                        'rating' => rand(4, 5), // Seed 4 or 5 stars to make Eom Seonghyeon look premium (like 4.7 average!)
                        'comment' => $comments[array_rand($comments)],
                        'created_at' => now()->subDays(rand(1, 15)),
                    ]);
                }
            }
        }
    }
}
