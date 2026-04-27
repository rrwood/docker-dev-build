# TODO - Future Improvements

## ✅ Script Location Inconsistency (COMPLETED)

**Issue:** Helper scripts were split between two locations

**Current State:**
- `setup-claude`, `setup-litellm`, `install-ngrok` → installed to `/usr/local/bin/` (global)
- `change-password.sh`, `generate-ssh-keys.sh`, `verify-env.sh`, `container-info.sh` → installed to `~/setup/` (user-specific)

**Desired State:**
- All setup scripts should be in `~/setup/` for consistency and user context

**Files to Modify:**
1. **Dockerfile** - Change script copy destinations:
   ```dockerfile
   # Current (line ~50-55):
   RUN cp /tmp/setup-repo/scripts/install-ngrok.sh /usr/local/bin/install-ngrok && \
       cp /tmp/setup-repo/scripts/setup-litellm.sh /usr/local/bin/setup-litellm && \
       cp /tmp/setup-repo/scripts/setup-claude.sh /usr/local/bin/setup-claude
   
   # Should be:
   RUN mkdir -p /home/${USERNAME}/setup && \
       cp /tmp/setup-repo/scripts/install-ngrok.sh /home/${USERNAME}/setup/ && \
       cp /tmp/setup-repo/scripts/setup-litellm.sh /home/${USERNAME}/setup/ && \
       cp /tmp/setup-repo/scripts/setup-claude.sh /home/${USERNAME}/setup/ && \
       chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/setup
   ```

2. **Documentation** - Update all references from commands like `setup-claude` to `~/setup/setup-claude.sh`
   - README.md (lines 133-151)
   - QUICKSTART.md (lines 116-167)
   - PORTAINER_DEPLOY.md (lines 143-163)
   - setup/README.md

3. **Testing:**
   - Verify scripts run correctly from ~/setup/
   - Update any PATH-dependent logic if needed
   - Test that all three scripts work after move

**Impact:**
- Low priority - scripts work fine from /usr/local/bin
- Cosmetic/organizational improvement
- Better user experience (all setup scripts in one place)

**Workaround:**
- Current location works fine, just inconsistent

---

## Future Enhancements

(Add other improvements here as needed)
