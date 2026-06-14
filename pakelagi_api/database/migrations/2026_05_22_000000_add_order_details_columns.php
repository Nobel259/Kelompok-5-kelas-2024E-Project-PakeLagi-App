<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('status')->default('pending_payment')->after('price');
            $table->string('shipping_code')->nullable()->after('status');
            $table->string('payment_proof')->nullable()->after('shipping_code');
            $table->string('buyer_name')->nullable()->after('payment_proof');
            $table->text('buyer_address')->nullable()->after('buyer_name');
            $table->string('buyer_phone')->nullable()->after('buyer_address');
            $table->text('buyer_notes')->nullable()->after('buyer_phone');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['status', 'shipping_code', 'payment_proof', 'buyer_name', 'buyer_address', 'buyer_phone', 'buyer_notes']);
        });
    }
};
