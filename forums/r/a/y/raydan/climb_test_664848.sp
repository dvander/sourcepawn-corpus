#pragma semicolon 1
#include <sourcemod>
#include <climb>

public Plugin:myinfo = 
{
    name = "Climb Map Timer Test",
    author = "Raydan",
    description = "Climb Map Timer Test",
    version = "1.0",
    url = "http://www.zombiex2.net"
};

public CL_OnStartTimerPress(client)
{
	PrintToChat(client,"You press start timer!");
}
public CL_OnEndTimerPress(client)
{
	PrintToChat(client,"You press end timer!");
}