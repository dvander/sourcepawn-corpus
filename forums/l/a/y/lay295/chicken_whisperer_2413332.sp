#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "Chicken Whisperer",
	author = "Mr.Derp",
	description = "Enable +use on chickens",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	
}

public OnEntityCreated(entity, const String:classname[]) {  
    if(StrEqual(classname, "chicken")) {
        SDKHook(entity, SDKHook_UsePost, Hook_OnEntityUse);  
    }
}

public Action:Hook_OnEntityUse(entity) { 
	return Plugin_Handled;  
}