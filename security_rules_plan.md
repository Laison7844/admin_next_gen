# NextGen Excellence Academy – CMS Firestore Security Rules Plan (Phase 2)

## 1. Single Administrator Authorization Boundary

In accordance with Phase 2 review requirements:
- **Sole Security Boundary:** The Firebase Authentication UID (`request.auth.uid`) is the exclusive gatekeeper in Firestore Security Rules.
- **No Custom Claims:** Custom claims (`request.auth.token.admin`) have been removed to enforce that only the single designated administrative account can ever execute CMS write actions.
- **No Self-Assignment:** Users cannot grant themselves admin access because the UID is directly matched in the rules engine.
- **Consistent Configuration:** The exact same UID (`p6awFfdX9jRKAScGwvSU9OMXjm72`) is configured in the CMS client app (`AdminConfig.authorizedAdminUid`).

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAdmin() {
      return request.auth != null &&
          request.auth.uid == 'p6awFfdX9jRKAScGwvSU9OMXjm72';
    }
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
> **NO RULES HAVE BEEN DEPLOYED.** As requested in the instructions, these security rules are prepared in `firestore.rules` and documented here for review. They will be deployed only when explicitly authorized.
