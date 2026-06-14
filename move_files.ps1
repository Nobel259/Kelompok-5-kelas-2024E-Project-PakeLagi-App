$lib = 'c:\Users\Nobel\kepake_lagi\lib'
New-Item -ItemType Directory -Force -Path "$lib\screens\auth"
New-Item -ItemType Directory -Force -Path "$lib\screens\main"
New-Item -ItemType Directory -Force -Path "$lib\screens\profile"
New-Item -ItemType Directory -Force -Path "$lib\screens\product"
New-Item -ItemType Directory -Force -Path "$lib\screens\seller"
New-Item -ItemType Directory -Force -Path "$lib\screens\order"
New-Item -ItemType Directory -Force -Path "$lib\screens\chat"
New-Item -ItemType Directory -Force -Path "$lib\screens\review"
New-Item -ItemType Directory -Force -Path "$lib\widgets"
New-Item -ItemType Directory -Force -Path "$lib\core"

Move-Item -Path "$lib\landing_page.dart" -Destination "$lib\screens\auth"
Move-Item -Path "$lib\login_page.dart" -Destination "$lib\screens\auth"
Move-Item -Path "$lib\register_page.dart" -Destination "$lib\screens\auth"

Move-Item -Path "$lib\main.dart" -Destination "$lib\screens\main"
Move-Item -Path "$lib\search_page.dart" -Destination "$lib\screens\main"
Move-Item -Path "$lib\favorites_page.dart" -Destination "$lib\screens\main"
Move-Item -Path "$lib\cart_page.dart" -Destination "$lib\screens\main"

Move-Item -Path "$lib\profile_page.dart" -Destination "$lib\screens\profile"
Move-Item -Path "$lib\view_profile_page.dart" -Destination "$lib\screens\profile"
Move-Item -Path "$lib\edit_profile_page.dart" -Destination "$lib\screens\profile"
Move-Item -Path "$lib\settings_page.dart" -Destination "$lib\screens\profile"
Move-Item -Path "$lib\account_settings_page.dart" -Destination "$lib\screens\profile"
Move-Item -Path "$lib\add_address_page.dart" -Destination "$lib\screens\profile"
Move-Item -Path "$lib\bank_settings_page.dart" -Destination "$lib\screens\profile"
Move-Item -Path "$lib\map_picker_page.dart" -Destination "$lib\screens\profile"
Move-Item -Path "$lib\notification_page.dart" -Destination "$lib\screens\profile"

Move-Item -Path "$lib\product_detail_page.dart" -Destination "$lib\screens\product"
Move-Item -Path "$lib\category_products_page.dart" -Destination "$lib\screens\product"
Move-Item -Path "$lib\recently_viewed_page.dart" -Destination "$lib\screens\product"

Move-Item -Path "$lib\sell_page.dart" -Destination "$lib\screens\seller"
Move-Item -Path "$lib\seller_profile_page.dart" -Destination "$lib\screens\seller"
Move-Item -Path "$lib\seller_address_page.dart" -Destination "$lib\screens\seller"
Move-Item -Path "$lib\brand_picker_page.dart" -Destination "$lib\screens\seller"
Move-Item -Path "$lib\category_picker_page.dart" -Destination "$lib\screens\seller"
Move-Item -Path "$lib\condition_picker_page.dart" -Destination "$lib\screens\seller"
Move-Item -Path "$lib\cropper_page.dart" -Destination "$lib\screens\seller"
Move-Item -Path "$lib\size_picker_page.dart" -Destination "$lib\screens\seller"
Move-Item -Path "$lib\subcategory_picker_page.dart" -Destination "$lib\screens\seller"

Move-Item -Path "$lib\checkout_page.dart" -Destination "$lib\screens\order"
Move-Item -Path "$lib\orders_page.dart" -Destination "$lib\screens\order"
Move-Item -Path "$lib\order_detail_page.dart" -Destination "$lib\screens\order"

Move-Item -Path "$lib\chat_list_page.dart" -Destination "$lib\screens\chat"
Move-Item -Path "$lib\chat_room_page.dart" -Destination "$lib\screens\chat"

Move-Item -Path "$lib\review_page.dart" -Destination "$lib\screens\review"
Move-Item -Path "$lib\write_review_page.dart" -Destination "$lib\screens\review"
Move-Item -Path "$lib\my_reviews_page.dart" -Destination "$lib\screens\review"

Move-Item -Path "$lib\review_list_widget.dart" -Destination "$lib\widgets"

Move-Item -Path "$lib\api_config.dart" -Destination "$lib\core"
