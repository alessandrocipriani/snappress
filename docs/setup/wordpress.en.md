# Connecting WordPress

SnapPress publishes to your site through the WordPress **REST API**, authenticating with an **Application Password**. No plugin is required.

## Site requirements

- **WordPress 5.6 or later** (Application Passwords are part of core since this version).
- **HTTPS enabled.** Without HTTPS, WordPress disables Application Passwords.
- **REST API reachable.** Open `https://yoursite.com/wp-json/` in a browser: you should see JSON. If you get an error, check security plugins, firewall or hosting settings.
- **A user with the Author, Editor or Administrator role.** Recommended: create a dedicated user (e.g. `snappress`) with the **Author** role, so the app does not use the administrator account.

## 1. Create the Application Password

1. Log in to WordPress as the user you will use.
2. Go to **Users → Profile**.
3. Scroll down to **Application Passwords**.
4. Enter `SnapPress` (or your phone's name) as the name and click **Add New Application Password**.
5. **Copy the password right away** (format `abcd efgh ijkl mnop qrst uvwx`): WordPress will not show it again.

Each password can be revoked individually from the same page, for example if you lose your phone.

## 2. Enter the details in SnapPress

In **Settings → Connections → WordPress**:

| Field | What to enter |
|---|---|
| Site address | `https://yoursite.com` (without `/wp-admin`) |
| Username | Your login username (not the password label) |
| Application Password | The copied password, with or without spaces |

Tap **Test connection**: SnapPress checks the credentials and the user's permissions.

## Common problems

| Symptom | Likely cause | Fix |
|---|---|---|
| No "Application Passwords" section | No HTTPS, WordPress older than 5.6, or disabled by a plugin | Enable HTTPS, update WordPress, check your security plugin settings (Wordfence, Solid Security, …) |
| 401 "rest_not_logged_in" | The server strips the `Authorization` header | On Apache add to `.htaccess`: `SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1`, or ask your host |
| 401 "invalid_username" | Wrong username | Use the login name, not the display name or email |
| 403 "rest_cannot_create" | Insufficient user role | Assign at least the Author role |
| 403 or firewall HTML page | Firewall or host blocks `/wp-json/` | Allow `/wp-json/wp/v2/` in the security plugin or hosting panel |
| Image upload rejected (413) | Image too large for the server | SnapPress resizes images; otherwise raise `upload_max_filesize` |

## What SnapPress does on your site

1. Uploads the image to the **Media Library** (`POST /wp-json/wp/v2/media`) with its alt text.
2. Creates the post (`POST /wp-json/wp/v2/posts`) as draft, published or scheduled, with featured image, categories and tags.

The public URL of the uploaded image is then reused for Instagram.
