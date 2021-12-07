#include <sourcemod>
#include <advancegunmenu>

public OnGunMenuSelect(const String:GunName[], const String:ClientName[], UserIndex)
{
	PrintToChat(UserIndex,"\x03%s \x05You have been given \x03%s", ClientName, GunName);
}

public OnGunMenuDisable()
{
	PrintToChatAll("\x03 The \x05 Gun menu \x03 has been disabled for the rest of the round!");
}

