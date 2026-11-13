const test = require('node:test');
const assert = require('node:assert');

const host = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const projectId = 'next-gen-excellence';
const baseUrl = `http://${host}/v1/projects/${projectId}/databases/(default)/documents`;

function createJwt(payload) {
  const header = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString('base64url');
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  return `${header}.${body}.`;
}

const verifiedAdminToken = createJwt({
  user_id: 'p6awFfdX9jRKAScGwvSU9OMXjm72',
  sub: 'p6awFfdX9jRKAScGwvSU9OMXjm72',
  email: 'admin@nextgen.edu'
});

const nonAdminToken = createJwt({
  user_id: 'unauthorized_attacker_uid_999',
  sub: 'unauthorized_attacker_uid_999',
  email: 'attacker@example.com'
});

// Helper for HTTP requests
async function firestoreReq({ path, method = 'GET', token, body }) {
  const headers = {};
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  if (body) {
    headers['Content-Type'] = 'application/json';
  }

  const res = await fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined
  });

  return {
    status: res.status,
    ok: res.ok,
    data: res.status !== 204 ? await res.json().catch(() => null) : null
  };
}

test('Firestore Security Rules Automated Validation Suite', async (t) => {

  // =========================================================================
  // 1. Public Content Read Permissions (Anonymous & Non-Admin Allowed)
  // =========================================================================
  await t.test('1. Anonymous visitors can read all public collections', async () => {
    const publicCollections = [
      'courses',
      'programs',
      'gallery',
      'faqs',
      'testimonials',
      'site_sections'
    ];

    for (const col of publicCollections) {
      // Document read should succeed or return 404 (NOT 403 Forbidden)
      const docRes = await firestoreReq({ path: `/${col}/sample_doc` });
      assert.notStrictEqual(docRes.status, 403, `Anonymous read on ${col} document was forbidden (403)`);

      // Collection list should succeed (200)
      const listRes = await firestoreReq({ path: `/${col}` });
      assert.strictEqual(listRes.status, 200, `Anonymous list on ${col} failed with status ${listRes.status}`);
    }
  });

  // =========================================================================
  // 2. Public Content Write Rejection (Anonymous & Non-Admin Denied)
  // =========================================================================
  await t.test('2. Anonymous visitors cannot create, update or delete public content', async () => {
    const createRes = await firestoreReq({
      path: '/courses?documentId=anon_course',
      method: 'POST',
      body: { fields: { title: { stringValue: 'Hacked Course' } } }
    });
    assert.strictEqual(createRes.status, 403, 'Anonymous course creation was not forbidden');

    const patchRes = await firestoreReq({
      path: '/site_sections/home_hero',
      method: 'PATCH',
      body: { fields: { title: { stringValue: 'Hacked Hero' } } }
    });
    assert.strictEqual(patchRes.status, 403, 'Anonymous site_section patch was not forbidden');

    const deleteRes = await firestoreReq({
      path: '/programs/sample_prog',
      method: 'DELETE'
    });
    assert.strictEqual(deleteRes.status, 403, 'Anonymous program delete was not forbidden');
  });

  await t.test('3. Non-admin authenticated users cannot create, update or delete public content', async () => {
    const createRes = await firestoreReq({
      path: '/courses?documentId=non_admin_course',
      method: 'POST',
      token: nonAdminToken,
      body: { fields: { title: { stringValue: 'Attacker Course' } } }
    });
    assert.strictEqual(createRes.status, 403, 'Non-admin course creation was not forbidden');

    const patchRes = await firestoreReq({
      path: '/site_sections/home_hero',
      method: 'PATCH',
      token: nonAdminToken,
      body: { fields: { title: { stringValue: 'Attacker Hero' } } }
    });
    assert.strictEqual(patchRes.status, 403, 'Non-admin site_section update was not forbidden');

    const deleteRes = await firestoreReq({
      path: '/gallery/sample_item',
      method: 'DELETE',
      token: nonAdminToken
    });
    assert.strictEqual(deleteRes.status, 403, 'Non-admin gallery deletion was not forbidden');
  });

  // =========================================================================
  // 3. CMS Drafts Isolation (Admin-Only, Zero Public or Non-Admin Access)
  // =========================================================================
  await t.test('4. Anonymous and non-admin users cannot read or list cms_drafts', async () => {
    // Anonymous get & list
    const anonGet = await firestoreReq({ path: '/cms_drafts/draft_001' });
    assert.strictEqual(anonGet.status, 403, 'Anonymous get draft was not forbidden');

    const anonList = await firestoreReq({ path: '/cms_drafts' });
    assert.strictEqual(anonList.status, 403, 'Anonymous list drafts was not forbidden');

    // Non-admin get & list
    const nonAdminGet = await firestoreReq({ path: '/cms_drafts/draft_001', token: nonAdminToken });
    assert.strictEqual(nonAdminGet.status, 403, 'Non-admin get draft was not forbidden');

    const nonAdminList = await firestoreReq({ path: '/cms_drafts', token: nonAdminToken });
    assert.strictEqual(nonAdminList.status, 403, 'Non-admin list drafts was not forbidden');
  });

  await t.test('5. Non-admin users cannot write to cms_drafts', async () => {
    const nonAdminCreate = await firestoreReq({
      path: '/cms_drafts?documentId=draft_hack',
      method: 'POST',
      token: nonAdminToken,
      body: { fields: { title: { stringValue: 'Malicious Draft' } } }
    });
    assert.strictEqual(nonAdminCreate.status, 403, 'Non-admin draft create was not forbidden');
  });

  // =========================================================================
  // 4. Verified Admin Full Permissions
  // =========================================================================
  await t.test('6. Verified Admin UID can manage drafts and publish content', async () => {
    // Admin creates draft
    const draftCreate = await firestoreReq({
      path: '/cms_drafts?documentId=admin_test_draft',
      method: 'POST',
      token: verifiedAdminToken,
      body: { fields: { title: { stringValue: 'Approved Draft' } } }
    });
    assert.strictEqual(draftCreate.status, 200, `Admin draft create failed with status ${draftCreate.status}`);

    // Admin reads draft
    const draftRead = await firestoreReq({
      path: '/cms_drafts/admin_test_draft',
      token: verifiedAdminToken
    });
    assert.strictEqual(draftRead.status, 200, `Admin draft read failed with status ${draftRead.status}`);

    // Admin publishes course document
    const coursePublish = await firestoreReq({
      path: '/courses?documentId=published_math_1',
      method: 'POST',
      token: verifiedAdminToken,
      body: { fields: { title: { stringValue: 'Mathematics 1' } } }
    });
    assert.strictEqual(coursePublish.status, 200, `Admin course publish failed with status ${coursePublish.status}`);

    // Admin updates public site_section
    const siteSectionUpdate = await firestoreReq({
      path: '/site_sections/home_hero',
      method: 'PATCH',
      token: verifiedAdminToken,
      body: { fields: { mainTitle: { stringValue: 'NextGen Excellence Academy' } } }
    });
    assert.strictEqual(siteSectionUpdate.status, 200, `Admin site_section update failed with status ${siteSectionUpdate.status}`);

    // Admin deletes draft and course
    const draftDelete = await firestoreReq({
      path: '/cms_drafts/admin_test_draft',
      method: 'DELETE',
      token: verifiedAdminToken
    });
    assert.strictEqual(draftDelete.status, 200, 'Admin draft delete failed');

    const courseDelete = await firestoreReq({
      path: '/courses/published_math_1',
      method: 'DELETE',
      token: verifiedAdminToken
    });
    assert.strictEqual(courseDelete.status, 200, 'Admin course delete failed');
  });

  // =========================================================================
  // 5. Enquiries Collection Security & Schema Validation
  // =========================================================================
  await t.test('7. Enquiry submission succeeds with strict schema validation', async () => {
    const validEnquiry = {
      path: '/enquiries?documentId=9846001122',
      method: 'POST',
      body: {
        fields: {
          id: { stringValue: 'enq_1' },
          name: { stringValue: 'Priya Sharma' },
          phone: { stringValue: '9846001122' },
          program: { stringValue: 'Classes 1 - 7 Tuition' },
          message: { stringValue: 'Interested in admissions.' },
          status: { booleanValue: true },
          createdAt: { timestampValue: '2026-11-13T10:00:00Z' },
          updatedAt: { timestampValue: '2026-11-13T10:00:00Z' }
        }
      }
    };

    const submitRes = await firestoreReq(validEnquiry);
    assert.strictEqual(submitRes.status, 200, `Valid enquiry submission failed with status ${submitRes.status}`);
  });

  await t.test('8. Enquiry submission is rejected if schema validation fails', async () => {
    // 8a. Extra unexpected field
    const extraFieldEnquiry = {
      path: '/enquiries?documentId=9846001133',
      method: 'POST',
      body: {
        fields: {
          id: { stringValue: 'enq_2' },
          name: { stringValue: 'Rajesh' },
          phone: { stringValue: '9846001133' },
          program: { stringValue: 'Classes 8 - 10' },
          message: { stringValue: 'Inquiry' },
          status: { booleanValue: true },
          createdAt: { timestampValue: '2026-11-13T10:00:00Z' },
          updatedAt: { timestampValue: '2026-11-13T10:00:00Z' },
          isAdminRole: { booleanValue: true } // Disallowed key!
        }
      }
    };
    const extraRes = await firestoreReq(extraFieldEnquiry);
    assert.strictEqual(extraRes.status, 403, 'Enquiry with extra keys was not rejected (403)');

    // 8b. Mismatched phone in payload vs document ID
    const mismatchedPhoneEnquiry = {
      path: '/enquiries?documentId=9846001144',
      method: 'POST',
      body: {
        fields: {
          id: { stringValue: 'enq_3' },
          name: { stringValue: 'Anil' },
          phone: { stringValue: '1234567890' }, // Does not match doc ID 9846001144!
          program: { stringValue: 'Computer Tuition' },
          message: { stringValue: 'Inquiry' },
          status: { booleanValue: true },
          createdAt: { timestampValue: '2026-11-13T10:00:00Z' },
          updatedAt: { timestampValue: '2026-11-13T10:00:00Z' }
        }
      }
    };
    const mismatchRes = await firestoreReq(mismatchedPhoneEnquiry);
    assert.strictEqual(mismatchRes.status, 403, 'Enquiry with mismatched phone was not rejected (403)');

    // 8c. Status is not true
    const invalidStatusEnquiry = {
      path: '/enquiries?documentId=9846001155',
      method: 'POST',
      body: {
        fields: {
          id: { stringValue: 'enq_4' },
          name: { stringValue: 'Meena' },
          phone: { stringValue: '9846001155' },
          program: { stringValue: '1-1 Care' },
          message: { stringValue: 'Inquiry' },
          status: { booleanValue: false }, // Must be true!
          createdAt: { timestampValue: '2026-11-13T10:00:00Z' },
          updatedAt: { timestampValue: '2026-11-13T10:00:00Z' }
        }
      }
    };
    const statusRes = await firestoreReq(invalidStatusEnquiry);
    assert.strictEqual(statusRes.status, 403, 'Enquiry with status != true was not rejected (403)');
  });

  // =========================================================================
  // 6. Enquiry Reads & Delete Authorization
  // =========================================================================
  await t.test('9. Enquiry reads match current rules (public for Android compatibility)', async () => {
    // Read specific enquiry
    const getRes = await firestoreReq({ path: '/enquiries/9846001122' });
    assert.strictEqual(getRes.status, 200, 'Public read of existing enquiry failed');

    // List enquiries
    const listRes = await firestoreReq({ path: '/enquiries' });
    assert.strictEqual(listRes.status, 200, 'Public list of enquiries failed');
  });

  await t.test('10. Enquiry deletion is strictly restricted to verified admin', async () => {
    // Anonymous delete rejected
    const anonDel = await firestoreReq({
      path: '/enquiries/9846001122',
      method: 'DELETE'
    });
    assert.strictEqual(anonDel.status, 403, 'Anonymous enquiry deletion was not forbidden');

    // Non-admin delete rejected
    const nonAdminDel = await firestoreReq({
      path: '/enquiries/9846001122',
      method: 'DELETE',
      token: nonAdminToken
    });
    assert.strictEqual(nonAdminDel.status, 403, 'Non-admin enquiry deletion was not forbidden');

    // Verified admin delete allowed
    const adminDel = await firestoreReq({
      path: '/enquiries/9846001122',
      method: 'DELETE',
      token: verifiedAdminToken
    });
    assert.strictEqual(adminDel.status, 200, 'Verified admin enquiry deletion failed');
  });

  // =========================================================================
  // 7. Overlapping Path & Wildcard Verification
  // =========================================================================
  await t.test('11. Undefined or arbitrary collections are denied by default', async () => {
    const anonArbitrary = await firestoreReq({ path: '/arbitrary_admin_secrets/doc_1' });
    assert.strictEqual(anonArbitrary.status, 403, 'Arbitrary collection read was not denied by default');

    const nonAdminArbitrary = await firestoreReq({
      path: '/users/user_1',
      token: nonAdminToken
    });
    assert.strictEqual(nonAdminArbitrary.status, 403, 'Undefined collection read for non-admin was not denied');
  });
});

