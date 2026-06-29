#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
public Plugin:myinfo =
{
name = "Force DL",
author = "darren",
description = "Forces Clients into downloading your files.",
version = "1.0",
url = ""
};
public OnPluginStart()
{
}
 
public OnMapStart()
{
AddFileToDownloadsTable("addons\\l4d1survivorarms.vpk");
}