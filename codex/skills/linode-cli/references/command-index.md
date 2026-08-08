# Command and action index

Generated from linode-cli 5.68.0's bundled OpenAPI data on 2026-08-08. This is a discovery index,
not a frozen signature reference. Run `linode-cli COMMAND ACTION --help` for current parameters.

- `account`: cancel, client-create/delete/reset-secret/update/view, clients-list, enable-managed,
  get-account-availability, get-availability, invoice-items/view, invoices-list, login-view,
  logins-list, maintenance-list, notifications-list, payment-create/view, payments-list, promo-add,
  settings, settings-update, transfer, update, view.
- `alerts`: channels-alerts-list/create/delete/list/update/view, definition-create/delete,
  definition-entities-list/update/view, definitions-list-all, service-definitions-list.
- `betas`: enroll, enrolled, enrolled-view, list, view.
- `child-account`: create, list (deprecated), view (deprecated).
- `databases`: engine-view, engines, list, mysql-config-view/create/creds-reset/creds-view/delete/list/
  patch/resume/ssl-cert/suspend/update/view, postgres-config-view, postgresql-conn-pool-create/delete/
  list/update, postgresql-create/creds-reset/creds-view/delete/list/patch/resume/ssl-cert/suspend/
  update/view, type-view, types, view.
- `domains`: clone, create, delete, import, list, records-create/delete/list/update/view, update, view,
  zone-file.
- `events`: list, mark-seen, view.
- `firewalls`: create, delete, device-create/delete/view, devices-list, firewall-settings-list/update,
  list, rules-list/update, template-view, templates-list, update, version-view, versions-list, view.
- `image-sharegroups`: create, delete, image-add/remove/update, images-list, images-list-by-token, list,
  member-add/delete/update/view, members-list, token-create/delete/update/view, tokens-list, update,
  view, view-by-token.
- `images`: create, delete, list, replicate, sharegroups-list, update, upload, view.
- `kernels`: list, view.
- `linodes`: backup-restore/view, backups-cancel/enable/list, boot, clone, config-create/delete/update/
  view, config-interface-add/delete/update/view, config-interfaces-list/order, configs-list, create,
  delete, disk-clone/create/delete/reset-password/resize/update/view, disks-list, firewalls-list/update,
  interface-add/delete/firewalls-list/history-list/settings-update/update/view, interfaces-list/
  settings-list/upgrade, ip-add/delete/update/view, ips-list, linode-reset-password, list, migrate,
  nodebalancers, post-apply-firewalls, reboot, rebuild, rescue, resize, shutdown, snapshot,
  transfer-view, type-view, types, update, upgrade, view, volumes.
- `lke`: api-endpoints-list, cluster-acl-delete/update/view, cluster-create/dashboard-url/delete/
  nodes-recycle/update/view, clusters-list, kubeconfig-delete/view, node-delete/recycle/view,
  pool-create/delete/recycle/update/view, pools-list, regenerate, service-token-delete,
  tiered-version-view, tiered-versions-list, types, version-view, versions-list.
- `longview`: create, delete, list, plan-update/view, subscription-view, subscriptions-list, types,
  update, view.
- `maintenance`: policies-list.
- `managed`: contact-create/delete/update/view, contacts-list, credential-create/revoke/sshkey-view/
  update/update-username-password/view, credentials-list, issue-view, issues-list,
  linode-setting-update/view, linode-settings-list, service-create/delete/disable/enable/update/view,
  services-list, stats-list.
- `marketplace`: contacts-create.
- `monitor`: dashboards-list, dashboards-list-all, dashboards-view, metrics-list, service-list/view,
  token-get.
- `network-transfer`: prices.
- `networking`: ip-add/assign/share/update/view, ips-list, v6-pools, v6-range-create/delete/view,
  v6-ranges.
- `nodebalancers`: config-create/delete/rebuild/update/view, configs-list, create, delete, firewalls,
  list, node-create/delete/update/view, nodes-list, types, update, view, vpc-view, vpcs-list.
- `object-storage`: cancel, clusters-list/view, endpoints, global-quota-usage-view,
  global-quota-view, global-quotas-list, keys-create/delete/list/update/view, quota-usage-view,
  quota-view, quotas-list, ssl-delete/upload/view, transfer-view, types.
- `payment-methods`: add, default, delete, list, view.
- `phone`: delete, sms-code-send, verify.
- `placement`: assign-linode, group-create/delete/update/view, groups-list, unassign-linode.
- `profile`: app-delete/view, apps-list, device-revoke/view, devices-list, login-view, logins-list,
  tfa-confirm/disable/enable, token-create/delete/update/view, tokens-list, update, view.
- `regions`: list, list-avail, view, view-avail.
- `resource-locks`: create, delete, list/ls, view.
- `security-questions`: list.
- `service-transfers`: accept, cancel, create, list, view.
- `sshkeys`: create, delete, list, update, view.
- `stackscripts`: create, delete, list, update, view.
- `streams`: create, delete, destination-create/delete/history-view/update/view, destinations-list,
  history-view, list/ls, update, view.
- `tags`: create, delete, list.
- `tickets`: close, create, list, replies, reply, view.
- `users`: create, delete, list, update, view.
- `vlans`: delete, list.
- `volumes`: attach, clone, create, delete, detach, list, resize, types, update, view.
- `vpcs`: create, delete, ips-all-list, ips-list, list, subnet-create/delete/update/view,
  subnets-list, update, view.

CLI-local commands: `configure`, `set-user`, `show-users`, `remove-user`, `register-plugin`,
`remove-plugin`, and `completion`. Help topics: `env-vars`, `commands`, and `plugins`. Bundled plugin
commands: `monitor-api`, `obj`, `firewall-editor`, `get-kubeconfig`, `metadata`, `image-upload`,
`region-table`, and `ssh`.
