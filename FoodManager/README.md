# BIT240109_FoodManager

Flutter + SQLite app for the mobile development midterm assignment.

## Create/open project

The suggested Windows folder is `D:\Vs Code\FoodManager`.

If it does not exist yet, run:

```powershell
cd "D:\Vs Code"
flutter create FoodManager
cd FoodManager
```

Copy the supplied `pubspec.yaml` and `lib\main.dart` into the project, replacing the generated files.

## Install packages and run

```powershell
cd "D:\Vs Code\FoodManager"
flutter pub get
flutter doctor
flutter run
```

Use an Android emulator or connect a phone with USB debugging enabled.

## Included

- SQLite tables: `BIT240109_DishCategory`, `BIT240109_Dish`, `BIT240109_DishImage`
- All stored columns have the `BIT240109_` prefix.
- 3 seeded categories and 5 seeded dishes
- List, detail, create, edit and delete
- Search, category/status/price filters, sorting
- Multiple image URLs and a thumbnail
- Quick / Nhanh when preparation time <= 15 minutes
- English default and English/Vietnamese switch saved with SharedPreferences
- Name/price/time/category/duplicate-name validation
- List filter and sort state remains in the list page when navigating to details or form

## Important limitations / improvements before submission

1. The image field accepts remote HTTP(S) URLs; this simple version does not download or pick image files.
2. The app uses SQLite only. It does not implement MockAPI connectivity, an offline change queue, or automatic synchronization. Those are separate advanced requirements worth 1.5 points in the assignment.
3. The starter version seeds sample data only when the database is first created. If you need to reset sample data during testing, uninstall the app from the emulator or clear its app storage.
4. The app has a dish category selector but does not yet have a category-management screen. The exam requires preventing deletion of categories in use; no category deletion UI is provided in this starter version.
5. For production-grade language support, centralize every visible label in a localization file. This beginner-friendly version uses a simple `tr()` helper; some technical/system messages may still appear in English.
6. Thumbnail rule: the first image URL is the thumbnail. To change it in the form, move the desired URL to the first line.
7. Validate that image URLs are reachable during the demo; remote image hosting and Internet connectivity can affect display.

## Table and column naming examples

- Table: `BIT240109_Dish`
- Table: `BIT240109_DishCategory`
- Table: `BIT240109_DishImage`
- Column: `BIT240109_Name`
- Column: `BIT240109_DishCategoryId`
- Column: `BIT240109_ImageUrl`

## Demo checklist

- List shows sample dishes
- Search by partial name
- Filter by category, availability, minimum/maximum price together
- Try an invalid price range and show empty result
- Sort price ascending, price descending, and preparation time
- Open detail and show all images
- Create, edit and delete a dish
- Show validation errors for empty name, zero price, zero preparation time and duplicate name in same category
- Switch English/Vietnamese and navigate to another screen
- Show SQLite prefix in `lib/main.dart`
