# 🔐 GitHub Actions Authentication Troubleshooting

## ❌ Error: "Unauthenticated request - Unauthenticated requests do not have permission"

This error occurs when GitHub Actions cannot authenticate to GCP. 

---

## ✅ Solution: Add GitHub Secrets Correctly

### **Step 1: Check Your Secrets Are Added**

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

Look for these two secrets:
- ✅ `GCP_PROJECT_ID` 
- ✅ `GCP_SA_KEY`

**If they're NOT there**, follow Step 2.

---

### **Step 2: Add the Secrets**

#### **Secret 1: GCP_PROJECT_ID**
1. Click **"New repository secret"**
2. Name: `GCP_PROJECT_ID`
3. Value: 
   ```
   my-k8s-project-499007
   ```
4. Click **"Add secret"**

#### **Secret 2: GCP_SA_KEY** (IMPORTANT)
1. Click **"New repository secret"**
2. Name: `GCP_SA_KEY`
3. Get the value by running:
   ```bash
   cd terraform
   terraform output -raw github_secret_gcp_sa_key
   ```
4. **Copy the ENTIRE JSON output** (all 2391 characters)
5. Paste into GitHub secret value field
6. Click **"Add secret"**

**⚠️ CRITICAL**: Make sure you copy the **ENTIRE** JSON, including:
- The opening `{` at the start
- The closing `}` at the end
- All fields in between

---

### **Step 3: Verify Secret is Complete**

After adding the secret, GitHub doesn't show you the value for security. To verify it was added correctly:

1. Go to **Settings → Secrets and variables → Actions**
2. Click on `GCP_SA_KEY`
3. You should see: **"Last updated X minutes ago"**
4. The secret should show as filled (not empty)

---

### **Step 4: Re-run the Workflow**

Go to: **Actions → build-push-gcp → Run workflow**

OR push a new commit:
```bash
git add .
git commit -m "test workflow with secrets"
git push origin main
```

The workflow should now authenticate successfully.

---

## 🔍 Common Mistakes

### ❌ Mistake 1: Secret value is truncated
**Problem**: You only copied part of the JSON key
**Solution**: Make sure you copy ALL 2391 characters including `{` at start and `}` at end

### ❌ Mistake 2: Wrong secret name
**Problem**: Named it `GCP_KEY` instead of `GCP_SA_KEY`
**Solution**: Check exact names:
- `GCP_PROJECT_ID` (not `GCP_PROJECT` or `PROJECT_ID`)
- `GCP_SA_KEY` (not `GCP_KEY` or `GITHUB_KEY`)

### ❌ Mistake 3: Escaped or formatted JSON
**Problem**: JSON is escaped or has extra quotes
**Solution**: Paste the raw JSON directly, not formatted/escaped

### ❌ Mistake 4: Service account doesn't have permissions
**Problem**: Terraform created account but it's new
**Solution**: IAM roles take ~5-10 minutes to propagate. Wait and retry.

---

## ✅ Verification Steps

### Check 1: Verify Secrets Are Set
```bash
cd /home/tharindu/projects/k8s-research-k8s-poc/terraform
terraform output github_secrets_instructions
```

This shows the exact values to use.

### Check 2: Verify Service Account Has Roles
```bash
gcloud projects get-iam-policy my-k8s-project-499007 \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:github-actions-sa@my-k8s-project-499007.iam.gserviceaccount.com"
```

Should show:
```
ROLE
roles/artifactregistry.writer
roles/storage.admin
roles/viewer
```

### Check 3: Verify Key File Exists
```bash
ls -la ../key.json
chmod 600 ../key.json
cat ../key.json | jq .  # Pretty print the JSON
```

---

## 🛠️ If Secrets Are Already Added But Still Failing

### Option 1: Delete and Re-add the Secret
1. Go to **Settings → Secrets and variables → Actions**
2. Find `GCP_SA_KEY`
3. Click **"Delete"**
4. Wait 30 seconds
5. Add it again with the complete JSON value

### Option 2: Regenerate the Service Account Key
```bash
cd terraform

# Remove the old key from Terraform state
terraform state rm google_service_account_key.github_actions_key
terraform state rm local_sensitive_file.service_account_key

# Re-create the key
terraform apply

# Get the new key
terraform output -raw github_secret_gcp_sa_key

# Update the GitHub secret with the new value
```

### Option 3: Check Workflow File
Make sure `.github/workflows/build-push-gcp.yml` has:
```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}
```

---

## 📋 Quick Checklist

Before running the workflow, verify:

- [ ] Secret `GCP_PROJECT_ID` added with value: `my-k8s-project-499007`
- [ ] Secret `GCP_SA_KEY` added with full JSON (2391 characters)
- [ ] Service account has 3 IAM roles (artifactregistry.writer, storage.admin, viewer)
- [ ] Service account key exists: `../key.json`
- [ ] Workflow file references correct secrets: `${{ secrets.GCP_SA_KEY }}`
- [ ] Repository has been updated: `git push origin main`

---

## 🚀 After Fixing Authentication

1. Push code to trigger workflow:
   ```bash
   git push origin main
   ```

2. Monitor workflow in GitHub Actions tab

3. Verify images were pushed:
   ```bash
   gcloud artifacts docker images list \
     asia-south1-docker.pkg.dev/my-k8s-project-499007/containers \
     --include-tags
   ```

---

## 📞 Additional Help

**See these docs for more details**:
- [SETUP_STATUS.md](../SETUP_STATUS.md#step-1-add-github-secrets) - Setup steps
- [terraform/README.md](../terraform/README.md#troubleshooting) - Troubleshooting section
- [GCP_SETUP.md](../GCP_SETUP.md) - Manual verification commands

---

**Status**: Ready to authenticate once secrets are added ✅
