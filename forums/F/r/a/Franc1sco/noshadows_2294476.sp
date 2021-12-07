#include <sdktools>

public Plugin:myinfo =
{
	name = "SM very simple Shadows disabler",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug/"
};

public OnMapStart() 
{ 
    CreateEntityByName("shadow_control");
    new ent = -1; 
    while((ent = FindEntityByClassname(ent, "shadow_control")) != -1) 
    { 
        SetVariantInt(1); 
        AcceptEntityInput(ent, "SetShadowsDisabled"); 
    } 
} 