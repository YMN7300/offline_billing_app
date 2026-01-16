import 'package:flutter/material.dart';
import 'package:offline_billing/navigation_pages/appbar_buttons/profile.dart';
import 'package:offline_billing/navigation_pages/bottom_navigation/items_page.dart';
import 'package:offline_billing/navigation_pages/from_floating_button/for_home_page/add_vendor.dart';
//pages
import 'package:offline_billing/pages/create_acc_page.dart';
import 'package:offline_billing/pages/first_screen.dart';
import 'package:offline_billing/pages/forgot_password_page.dart';
import 'package:offline_billing/pages/log_in_page.dart';
import 'package:offline_billing/pages/reset_password_page.dart';
import 'package:offline_billing/pages/verification_code_page.dart';

import 'navigation_pages/appbar_buttons/notification.dart';
import 'navigation_pages/appbar_buttons/setting.dart';
import 'navigation_pages/bottom_navigation/bottom_navigation_page.dart';
import 'navigation_pages/bottom_navigation/home_page.dart';
import 'navigation_pages/from_floating_button/for_home_page/add_customer.dart';
import 'navigation_pages/from_floating_button/for_home_page/add_purchase.dart';
import 'navigation_pages/from_floating_button/for_home_page/add_purchase_item_page.dart';
import 'navigation_pages/from_floating_button/for_home_page/add_purchase_return.dart';
import 'navigation_pages/from_floating_button/for_home_page/add_purchase_return_item_page.dart';
import 'navigation_pages/from_floating_button/for_home_page/add_sales.dart';
import 'navigation_pages/from_floating_button/for_home_page/add_sales_item_page.dart';
import 'navigation_pages/from_floating_button/for_home_page/add_sales_return.dart';
import 'navigation_pages/from_floating_button/for_home_page/add_sales_return_item_page.dart';
import 'navigation_pages/from_floating_button/for_item_page/add_product.dart';
import 'navigation_pages/from_floating_button/for_more_page/about_us_page.dart';
import 'navigation_pages/from_floating_button/for_more_page/active_inactive_item.dart';
import 'navigation_pages/from_floating_button/for_more_page/add_bank_account.dart';
import 'navigation_pages/from_floating_button/for_more_page/cash_in_hand.dart';
import 'navigation_pages/from_floating_button/for_more_page/item_summary.dart';
import 'navigation_pages/from_floating_button/for_more_page/payment/card_for_purchase.dart';
import 'navigation_pages/from_floating_button/for_more_page/payment/card_from_sales.dart';
import 'navigation_pages/from_floating_button/for_more_page/payment/cash_for_purchase.dart';
import 'navigation_pages/from_floating_button/for_more_page/payment/cash_from_sales.dart';
import 'navigation_pages/from_floating_button/for_more_page/payment/upi_for_purchase.dart';
import 'navigation_pages/from_floating_button/for_more_page/payment/upi_from_sales.dart';
import 'navigation_pages/from_floating_button/for_more_page/privacy_policy_page.dart';
import 'navigation_pages/from_floating_button/for_more_page/purchase_list.dart';
import 'navigation_pages/from_floating_button/for_more_page/purchase_return_list.dart';
import 'navigation_pages/from_floating_button/for_more_page/sales_list.dart';
import 'navigation_pages/from_floating_button/for_more_page/sales_return_list.dart';
import 'navigation_pages/from_floating_button/for_more_page/stock_summary.dart';
import 'navigation_pages/from_floating_button/for_more_page/terms_and_conditions_page.dart';

void main() {
  runApp(
    MaterialApp(
      // theme: ThemeData(
      //   brightness: Brightness.light,
      //   primarySwatch: Colors.deepPurple,
      //   scaffoldBackgroundColor: Colors.white,
      //   // fontFamily: "Roboto",
      // ),

      // DARK THEME
      // darkTheme: ThemeData(
      //   brightness: Brightness.dark,
      //   primarySwatch: Colors.deepPurple,
      //   scaffoldBackgroundColor: Colors.black,
      //   // fontFamily: "Roboto",
      // ),

      // USE SYSTEM PREFERENCE
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: "first_screen",
      routes: {
        "first_screen": (context) => FirstScreen(),
        "log_in_page": (context) => LogInPage(),
        "create_acc_page": (context) => CreateAccPage(),
        "forgot_password_page": (context) => ForgotPasswordPage(),
        "verification_code_page": (context) => VerificationCodePage(),
        "reset_password_page": (context) => ResetPasswordPage(),
        "bottom_navigation_page": (context) => BottomNavigationPage(),
        "profile_page": (context) => ProfilePage(),
        "home_page": (context) => HomePage(),

        "add_product": (context) => AddProduct(),
        "item_page": (context) => ItemsPage(),
        "add_customer": (context) => AddCustomer(),
        "add_vendor": (context) => AddVendor(),
        "add_purchase": (context) => AddPurchase(),
        "add_purchase_item": (context) => AddPurchaseItemPage(),
        "add_sales": (context) => AddSales(),
        "add_sales_item": (context) => AddSalesItemPage(),
        "add_sales_return": (context) => AddSalesReturn(),
        "add_sales_return_item": (context) => AddSalesReturnItemPage(),
        "add_purchase_return": (context) => AddPurchaseReturn(),
        "add_purchase_return_item": (context) => AddPurchaseReturnItemPage(),
        "setting": (context) => SettingsPage(),
        "sales_list": (context) => SalesListPage(),
        "sales_return_list": (context) => SalesReturnListPage(),
        "purchase_list": (context) => PurchaseListPage(),
        "purchase_return_list": (context) => PurchaseReturnListPage(),
        "item_summary": (context) => ItemSummaryPage(),
        "stock_summary": (context) => StockSummaryPage(),
        "active_inactive_item": (context) => ActiveInactiveItemsPage(),
        "cash_in_hand": (context) => CashInHandPage(),
        "cash_from_sales": (context) => SalesCashPage(),
        "cash_for_purchase": (context) => PurchaseCashPage(),
        "card_from_sales": (context) => CardInHandSalesPage(),
        "card_for_purchase": (context) => CardInHandPurchasePage(),
        "upi_from_sales": (context) => UPISalesPage(),
        "upi_for_purchase": (context) => UPIPurchasePage(),
        "add_bank_account": (context) => AddBankAccountPage(),
        "notification": (context) => NotificationPage(),
        "about_us": (context) => AboutUsPage(),
        "privacy_policy": (context) => PrivacyPolicyPage(),
        "terms_&_condition": (context) => TermsAndConditionsPage(),
      },
    ),
  );
}
