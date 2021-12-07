#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#define PLUGIN_VERSION "1.0a"

public Plugin:myinfo = 
{
	name = "UnitedSB Streams",
	author = "rEViDE",
	description = "Streams Shouted.FM mth.Break (http://www.shouted.fm/break)",
	version = PLUGIN_VERSION,
	url = "http://usb-clan.de/"
}
new Handle:stream_url;
new Handle:stream_site;
new Handle:stream_name;
new Handle:stream_image;
public OnPluginStart()
{
	RegConsoleCmd("sm_radio", Command_Radio);
	CreateConVar("usb_stream_version", PLUGIN_VERSION, "UnitedSB Stream Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	stream_url = CreateConVar("stream_url", "http://www.shouted.fm/tunein/break-dsl.m3u", "Sets your Stream URL");
	stream_site = CreateConVar("stream_site", "http://www.shouted.fm/", "Sets your Stream Site URL");
	stream_image = CreateConVar("stream_img", "http://www.unitedsb.de/sfb.png", "Sets your Stream image displayed on !radio");
	stream_name = CreateConVar("stream_name", "mth.Break", "Sets your Stream Name");
	AutoExecConfig(true, "plugin.usb_stream");
}
public Action:Command_Radio(client, args)
{
	new Handle:menu2 = CreateMenu(Radio);
	decl String:title[100];
	Format(title, sizeof(title), "Shouted.FM mth.Break");
	SetMenuTitle(menu2, title);
	SetMenuExitButton(menu2, true);
	new String:name[60], String:name2[128];
	GetConVarString(stream_name, name, 128);
	Format(name2, 128, "Turn %s on", name);
	AddMenuItem(menu2, "An", name2, ITEMDRAW_DEFAULT);
	Format(name2, 128, "Turn %s off", name);
	AddMenuItem(menu2, "Aus", name2, ITEMDRAW_DEFAULT);
	AddMenuItem(menu2, "Info", "Stream Plugin by rEViDE", ITEMDRAW_DISABLED);
	AddMenuItem(menu2, "Info", "Dedicated to SHOUTED.FM", ITEMDRAW_DISABLED);
	AddMenuItem(menu2, "Info", "by UnitedSB Clan", ITEMDRAW_DISABLED);
	DisplayMenu(menu2, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Radio(Handle:menu, MenuAction:action, client, param2){
	new String:info[32];
	GetMenuItem(menu, param2, info, 32);
	if(StrEqual("An", info, false)){
		new String:url[600],String:url2[256], String:img[256];
		GetConVarString(stream_url, url, 256);
		GetConVarString(stream_image, img, 256);
		Format(url2, 256, "http://www.unitedsb.de/radio.php?site=%s&img=%s", url, img);
		ShowMOTDPanel(client, "Shouted.FM mth.Break", url2, MOTDPANEL_TYPE_URL);
	}
	if(StrEqual("Aus", info, false)){
		new String:url[128];
		GetConVarString(stream_site, url, 128);
		ShowMOTDPanel(client, "Shouted.FM mth.Break", url, MOTDPANEL_TYPE_URL);
	}
}
