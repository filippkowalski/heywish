# HeyWish Technical Specification

## Database Schema

This document defines the PostgreSQL database schema for the HeyWish project.

### Users

The `users` table stores information about users, synced from Firebase Authentication.

| Column         | Type        | Constraints      | Description                                  |
|----------------|-------------|------------------|----------------------------------------------|
| `id`           | `uuid`      | `PRIMARY KEY`    | Unique identifier for the user.              |
| `firebase_uid` | `text`      | `UNIQUE NOT NULL`| Firebase user ID.                            |
| `email`        | `text`      | `UNIQUE`         | User's email address.                        |
| `username`     | `text`      | `UNIQUE`         | User's unique username.                      |
| `full_name`    | `text`      |                  | User's full name.                            |
| `avatar_url`   | `text`      |                  | URL for the user's avatar image.             |
| `is_anonymous` | `boolean`   | `NOT NULL`       | Whether the user is anonymous.               |
| `created_at`   | `timestamptz`| `NOT NULL`      | Timestamp when the user was created.         |
| `updated_at`   | `timestamptz`| `NOT NULL`      | Timestamp when the user was last updated.    |

### Wishlists

The `wishlists` table stores wishlists created by users.

| Column          | Type        | Constraints   | Description                                     |
|-----------------|-------------|---------------|-------------------------------------------------|
| `id`            | `uuid`      | `PRIMARY KEY` | Unique identifier for the wishlist.             |
| `user_id`       | `uuid`      | `FOREIGN KEY` | The user who owns the wishlist.                 |
| `name`          | `text`      | `NOT NULL`    | The name of the wishlist.                       |
| `description`   | `text`      |               | A description of the wishlist.                  |
| `visibility`    | `text`      | `NOT NULL`    | Visibility of the wishlist (e.g., `public`, `friends`, `private`). |
| `cover_image_url`| `text`     |               | URL for the wishlist's cover image.             |
| `share_token`   | `text`      | `UNIQUE`      | A unique token for sharing the wishlist.        |
| `created_at`    | `timestamptz`| `NOT NULL`   | Timestamp when the wishlist was created.        |
| `updated_at`    | `timestamptz`| `NOT NULL`   | Timestamp when the wishlist was last updated.   |

### Wishes

The `wishes` table stores individual items in a wishlist.

| Column         | Type        | Constraints   | Description                                     |
|----------------|-------------|---------------|-------------------------------------------------|
| `id`           | `uuid`      | `PRIMARY KEY` | Unique identifier for the wish.                 |
| `wishlist_id`  | `uuid`      | `FOREIGN KEY` | The wishlist this wish belongs to.              |
| `title`        | `text`      | `NOT NULL`    | The title of the wish.                          |
| `description`  | `text`      |               | A description of the wish.                      |
| `url`          | `text`      |               | A URL for the product.                          |
| `price`        | `numeric`   |               | The price of the product.                       |
| `currency`     | `text`      |               | The currency of the price.                      |
| `images`       | `text[]`    |               | An array of URLs for product images.            |
| `status`       | `text`      | `NOT NULL`    | The status of the wish (e.g., `available`, `reserved`, `purchased`). |
| `priority`     | `integer`   |               | The priority of the wish.                       |
| `quantity`     | `integer`   | `NOT NULL`    | The quantity of the item desired.               |
| `notes`        | `text`      |               | Any notes about the wish.                       |
| `reserved_by`  | `uuid`      | `FOREIGN KEY` | The user who reserved the wish.                 |
| `reserved_at`  | `timestamptz`|               | Timestamp when the wish was reserved.           |
| `purchased_at` | `timestamptz`|               | Timestamp when the wish was purchased.          |
| `added_at`     | `timestamptz`| `NOT NULL`   | Timestamp when the wish was added to the wishlist. |

### Friendships

The `friendships` table stores relationships between users.

| Column      | Type        | Constraints   | Description                                     |
|-------------|-------------|---------------|-------------------------------------------------|
| `user_id_1` | `uuid`      | `FOREIGN KEY` | The first user in the relationship.             |
| `user_id_2` | `uuid`      | `FOREIGN KEY` | The second user in the relationship.            |
| `status`    | `text`      | `NOT NULL`    | The status of the friendship (e.g., `pending`, `accepted`). |
| `created_at`| `timestamptz`| `NOT NULL`   | Timestamp when the relationship was created.    |

### Activities

The `activities` table stores a feed of actions taken by users.

| Column      | Type        | Constraints   | Description                                     |
|-------------|-------------|---------------|-------------------------------------------------|
| `id`        | `uuid`      | `PRIMARY KEY` | Unique identifier for the activity.             |
| `user_id`   | `uuid`      | `FOREIGN KEY` | The user who performed the action.              |
| `type`      | `text`      | `NOT NULL`    | The type of activity (e.g., `wish_added`, `friend_accepted`). |
| `data`      | `jsonb`     |               | Additional data about the activity.             |
| `timestamp` | `timestamptz`| `NOT NULL`   | Timestamp when the activity occurred.           |
