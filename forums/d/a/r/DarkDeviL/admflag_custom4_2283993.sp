public OnClientPostAdminFilter(client) {
  AddUserFlags(client, Admin_Custom4);
}

public OnClientDisconnect(client) {
  RemoveUserFlags(client, Admin_Custom4);
}
