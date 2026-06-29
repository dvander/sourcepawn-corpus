#include <sourcemod> 
#include <sdktools> 

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{ 
    if(buttons & IN_JUMP) 
        FakeClientCommand(client, "+jetpack"); 
    else 
        FakeClientCommand(client, "-jetpack"); 
}  