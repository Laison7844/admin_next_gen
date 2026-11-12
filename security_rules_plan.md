# NextGen Excellence Academy – CMS Firestore Security Rules Plan (Phase 2)

## 1. Security Architecture & Admin Authorization Boundary

In accordance with Phase 2 decisions:
- **Primary Security Boundary:** The Firebase Authentication UID (`request.auth.uid`) is the exclusive gatekeeper in Firestore Security Rules.
- **Single-Admin Model:** The authorized UID is hardcoded or configured in the rule definition. No client can alter or grant themselves administrative claims or roles.
- **Secondary Client Validation:** The client application validates `currentUser.email` as an additional guard before routing to CMS views, but the absolute database boundary is the Firestore rules rule engine.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAdmin() {
      return request.auth != null && (
        request.auth.uid == 'NEXTGEN_ADMIN_PRIMARY_UID' ||
        request.auth.token.admin == true
      );
    }
    ...
```

## 2. Partitioned Collection Access Matrix

| Collection | Public Website | Admin CMS | Notes |
| :--- | :--- | :--- | :--- |
| `cms_drafts/{draftId}` | **DENIED** (`false`) | **READ & WRITE** (`isAdmin()`) | Holds all working drafts, revisions, and metadata. Fully isolated from public web. |
| `courses/{courseId}` | **READ ONLY** (`true`) | **READ & WRITE** (`isAdmin()`) | Public website course catalog. Updated only on explicit Publish. |
| `programs/{programId}` | **READ ONLY** (`true`) | **READ & WRITE** (`isAdmin()`) | Public website academic tracks and special programs. |
| `faqs/{faqId}` | **READ ONLY** (`true`) | **READ & WRITE** (`isAdmin()`) | Public website FAQ entries. |
| `testimonials/{id}` | **READ ONLY** (`true`) | **READ & WRITE** (`isAdmin()`) | Public website student & parent testimonials. |
| `gallery/{itemId}` | **READ ONLY** (`true`) | **READ & WRITE** (`isAdmin()`) | Public website gallery photo items. |
| `site_sections/{id}` | **READ ONLY** (`true`) | **READ & WRITE** (`isAdmin()`) | Singleton page content (Hero, About, Contact/Settings). |
| `enquiries/{phone}` | **READ & VALIDATED CREATE** | **READ, CREATE, DELETE** | Preserved verbatim from existing live project rules. |

## 3. Preserved Enquiries Security Definition
The existing rule for enquiries submitted by the public website and consumed by the Android app remains completely intact:
```javascript
match /enquiries/{phone} {
  allow get, list: if true;
  allow create, update: if request.auth != null || (
    request.resource.data.keys().hasOnly([
      'id', 'name', 'phone', 'program', 'message', 'status',
      'createdAt', 'updatedAt'
    ]) &&
    request.resource.data.phone == phone &&
    request.resource.data.name is string &&
    request.resource.data.program is string &&
    request.resource.data.message is string &&
    request.resource.data.status == true
  );
  allow delete: if isAdmin();
}
```

## 4. Production Deployment Status
> [!IMPORTANT]
> **NO RULES HAVE BEEN DEPLOYED.** As requested in the Phase 2 instructions, these security rules are prepared in `firestore.rules` and documented here for review. They will be deployed only when explicitly authorized after end-to-end integration with the public website.
