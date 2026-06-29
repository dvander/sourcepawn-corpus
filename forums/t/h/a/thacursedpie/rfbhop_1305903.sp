/////////////////////////////////////////////////////////
//
//            Real Fake bHop
//              by thaCURSEDpie
//
//			  2010-09-15
//
//            v0.1
//
//
//             Thanks to Caesium for the inspiration!
//             (and also my brother for asking me to
//              make it :P)
//
/////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////
//
//         Includes
//
////////////////////////////////////////////////////////
#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>




/////////////////////////////////////////////////////////
//
//         Global variables
//
/////////////////////////////////////////////////////////
new Handle:Multiplier = INVALID_HANDLE;
new Handle:maxSpeed = INVALID_HANDLE;
new Handle:Enabled = INVALID_HANDLE;
new Handle:maxReactionTolerance = INVALID_HANDLE;
new Handle:angleMultiplier = INVALID_HANDLE;

new Float:currentMaxSpeed = 640.0;
new Float:bhopMultiplier = 1.0;
new Float:jumpVelocity[33][3];
new Float:currentAngleMultiplier = 4.0;

new bool:modEnabled = true;
new bool:showSpeedo[33];
new bool:jumpEventThisFrame[33];
new bool:wasJumpKeyPressed[33];

new Float:lastVelocity[33][3];
new frameCounter[33];
new maxFrameCount = 7;

static Float:Pi = 3.1415926535897932384626433832795028841971693993751058209;


/////////////////////////////////////////////////////////
//
//         Mod description
//
/////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name = "Real Fake bHop",
	author = "thaCURSEDpie",
	description = "This plugin is an attempt to restore the art of bHopping in TF2",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}


/////////////////////////////////////////////////////////
//
//         OnPluginStart
//
//         Notes:
//          Initialize all the cvars and hook their
//          change.
//          Also create a client command for the speedo
//
/////////////////////////////////////////////////////////
public OnPluginStart()
{
	CreateConVar("rfbhop_version", PLUGIN_VERSION, "Real Fake bHop by thaCURSEDpie", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	Multiplier = CreateConVar("rfbhop_multiplier", "1.0", "Multiplier to use with the bhop boost", FCVAR_PLUGIN);
	maxSpeed = CreateConVar("rfbhop_maxspeed", "640.0", "Max speed in units/second. (-1 = no max speed)", FCVAR_PLUGIN, true, -1.0);
	Enabled = CreateConVar("rfbhop_enabled", "1", "Enable the Real Fake bHop mod", FCVAR_PLUGIN);
	maxReactionTolerance = CreateConVar("rfbhop_tolerance", "7", "Amount of frames a player is allowed to touch the ground before bhop expires", FCVAR_PLUGIN, true);
	angleMultiplier = CreateConVar("rfbhop_angleratio", "4", "Ratio between 'old' speedvector-direction and 'new' speedvector-direction. (-1 = use old direction: saves CPU)", FCVAR_PLUGIN, true, -1.0);
	
	modEnabled = GetConVarBool(Enabled);
	currentMaxSpeed = GetConVarFloat(maxSpeed);
	bhopMultiplier = GetConVarFloat(Multiplier);

	HookConVarChange(Enabled, OnEnabledChanged);
	HookConVarChange(maxSpeed, OnMaxSpeedChanged);
	HookConVarChange(Multiplier, OnMultiplierChanged);
	HookConVarChange(maxReactionTolerance, OnToleranceChanged);
	HookConVarChange(angleMultiplier, OnAngleMultiplierChanged);
	
	RegConsoleCmd("sm_speedo", CmdSpeedoSwitch);
	
	// Default setting: show speedo
	for (new i = 0; i < 33; i++)
	{
		showSpeedo[i] = true;
	}
}


/////////////////////////////////////////////////////////
//
//         OnClientPutInServer
//
//         Notes:
//          This gets fired when the client is put in
//           the server
//          Add the PostThink hook, using SDKHooks
//
/////////////////////////////////////////////////////////
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThink, OnPostThink);
}


/////////////////////////////////////////////////////////
//
//         OnCvarChange
//
//         Notes:
//          Change the respective variables on cvar
//          change.
/////////////////////////////////////////////////////////
public OnMaxSpeedChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	currentMaxSpeed = GetConVarFloat(maxSpeed);
}

public OnAngleMultiplierChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	currentAngleMultiplier = GetConVarFloat(angleMultiplier);
}

public OnToleranceChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	maxFrameCount = GetConVarInt(maxReactionTolerance);
}

public OnEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	modEnabled = GetConVarBool(Enabled);
}

public OnMultiplierChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bhopMultiplier = GetConVarFloat(Multiplier);
}


/////////////////////////////////////////////////////////
//
//         CmdSpeedoSwitch
//
//         Notes:
//          Switches the speedo on/off on the client
//          
/////////////////////////////////////////////////////////
public Action:CmdSpeedoSwitch(client, args)
{
	showSpeedo[client] = !showSpeedo[client];
	PrintCenterText(client,"");
	return Plugin_Handled;
}


/////////////////////////////////////////////////////////
//
//         OnPlayerRunCmd
//
//         Notes:
//          This get's fired when the player sends
//          movement input to the server
//
//          In this function:
//          - jump detection
//          - calculations to decide the bhop boost
//          
/////////////////////////////////////////////////////////
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{    
	if (modEnabled)
	{
		// We first check if the JUMP button is being held,
		//  and if the FORWARD and BACKWARDS keys are NOT being held
		//  and that wasJumpKeyPressed[client]==false, which makes it a buttonPRESS, not HOLD
		if ((buttons & IN_JUMP) && !(buttons & IN_FORWARD) && !(buttons & IN_BACK) && !(wasJumpKeyPressed[client]))
		{
			// We now get the ground entity of the player
			//  0 = World (aka on ground) | -1 = In air | Any other positive value = CBaseEntity pointer to the entity below player.
			new GroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity"); 
			
			// We check if the player is in the air. If not:
			if (GroundEntity != -1)
			{			
				wasJumpKeyPressed[client] = true;
				jumpEventThisFrame[client] = true;
				
				// Initialize a vector to store the player velocity.
				new Float:PlayerVelocity[3];
				
				// We get the player velocity
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", PlayerVelocity);
				
				if (frameCounter[client] > maxFrameCount)
				{
					// We have exceeded the frame limit, thus: NO BOOST
					return Plugin_Continue;
				}
				
				// First we get an old speed (because Valve has been so kind to block bunnyhopping: your speed gets reset (almost) immediately as you hit the ground):
				new Float:tempVelocity[3];
				tempVelocity = lastVelocity[client];							
				
				// We now get the horizontal speed we are going to apply.
				new Float:tempSpeed = SquareRoot(tempVelocity[0]*tempVelocity[0] + tempVelocity[1]*tempVelocity[1]);
				
				// Angle-adjustment section
				if (currentAngleMultiplier != -1)
				{
					// Temp. floats initialization
					new Float:angle1 = 1.0;
					new Float:angle2 = 1.0;
					new Float:angle = 1.0;
					
					// Get the player's angle (heading) in radians
					//
					// Current angle 
					angle1 = GetPoleCoordinateAngle(PlayerVelocity[0], PlayerVelocity[1]);
					// Old angle
					angle2 = GetPoleCoordinateAngle(tempVelocity[0], tempVelocity[1]);					
					
					// If we were to use the heading of the OLD speed vector, bhopping would look glitchy to the player.
					// If we were to use the heading of the CURRENT speed vector, bhopping would be hard.
					//  you can customize this to your liking with the "rfbhop_angleratio" cvar
					
					// Do note that this does not have as much of an effect when "rfbhop_tolerance" is set very low ( < 5),
					//  because there would be very little difference between the old and the new angle.
					angle = (angle1 * currentAngleMultiplier + angle2) / (currentAngleMultiplier + 1);
					
					// There are some strange instances we need to filter out, else the player sometimes gets propelled backwards
					if ((angle2 < 0) && (angle1 >= 0))
					{
						angle = angle1;
					}
					else if ((angle1<0) && (angle2 >= 0) )
					{
						angle = angle1;
					}			
					
					// The speed is our 'radius'. We also know the angle, so we can retrieve our vector			
					tempVelocity[0] = tempSpeed * Cosine(angle);
					tempVelocity[1] = tempSpeed * Sine(angle);
				}

				// And now we apply the bhop boost
				// the "bhopMultiplier" can be changed to your liking with the "rfbhop_multiplier" cvar
				if ((tempSpeed > currentMaxSpeed) && (currentMaxSpeed != -1))
				{
					PlayerVelocity[0] = tempVelocity[0];
					PlayerVelocity[1] = tempVelocity[1];
				}
				else
				{
					PlayerVelocity[0] = bhopMultiplier * tempVelocity[0];
					PlayerVelocity[1] = bhopMultiplier * tempVelocity[1];
				}
				jumpVelocity[client] = PlayerVelocity;			
			}
			else // If the player IS in the air, he doesn't get a boost
			{
				jumpEventThisFrame[client] = false;
			}
		}	
		else // If the requirements arent met, the player doesn't get a boost
		{
			jumpEventThisFrame[client] = false;
		}
		
		// if the JUMP key is not held, we set the respective variable to FALSE
		if (!(buttons & IN_JUMP))
		{
			wasJumpKeyPressed[client] = false;
		}		
	}
	
	// We must return Plugin_Continue to let the changes be processed.      
	return Plugin_Continue; 
}


/////////////////////////////////////////////////////////
//
//         OnPostThink
//
//         Notes:
//          Name says it all...
//          In this function:
//          - speedometer
//          - bhop boost application
//          - saving current speed (if client is in air)
//          
/////////////////////////////////////////////////////////
public OnPostThink(client)
{
	// We check if the mod is running
	if (modEnabled)
	{
		// We check if the client is suitable
		if(IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
		{
			// We now get the ground entity of the player
			//  0 = World (aka on ground) | -1 = In air | Any other positive value = CBaseEntity pointer to the entity below player.
			new GroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity"); 			
			
			// Vector to store the player speed
			new Float:PlayerVelocity[3];
			
			// We get the player velocity
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", PlayerVelocity);
			
			// Speedo section	
			if (showSpeedo[client])
			{					
				// We get the player speed
				new Float:PlayerSpeed;
				PlayerSpeed = SquareRoot(PlayerVelocity[0]*PlayerVelocity[0] + PlayerVelocity[1]*PlayerVelocity[1]);
				
				// If a max speed is set, we use that to determine the 'speed' value
				if (currentMaxSpeed != -1)
				{
					PrintCenterText(client,"%i%", RoundFloat((PlayerSpeed/currentMaxSpeed) * 100));	
				}
				else // If no max speed is set, we use 640.0 as max speed
				{
					PrintCenterText(client,"%i%", RoundFloat((PlayerSpeed/640.0) * 100));
				}
			}	
			
			// If the player has behaved well, we reward him with a boost
			if ((jumpEventThisFrame[client]) && (frameCounter[client] <= maxFrameCount))
			{						
				// We use the current player velocity vector, because we do not want to specify the speed on the Z axis
				PlayerVelocity[0] = jumpVelocity[client][0];
				PlayerVelocity[1] = jumpVelocity[client][1];
				
				// We apply the boost
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, PlayerVelocity);				
			}
			
			// If the player is currently in the air, we save his velocity vector and set his framecounter to zero.
			if (GroundEntity == -1)
			{				
				lastVelocity[client] = PlayerVelocity;
				frameCounter[client] = 0;
			}
			else if (frameCounter[client] < maxFrameCount + 1)
			{
				// If the player is on the ground, we increase his framecounter
				frameCounter[client]++;				
			}
		}
		// We have handled the jump
		jumpEventThisFrame[client] = false;
	}
}


/////////////////////////////////////////////////////////
//
//         GetPoleCoordinateAngle
//
//         Notes:
//          Get the angle for the respective (carthesian)
//          coordinate
//          
/////////////////////////////////////////////////////////
Float:GetPoleCoordinateAngle(Float:x, Float:y)
{
	// set this to an arbitrary value, which we can use for error-checking
	new Float:theta=1337.00;
	
	// some math :)
	if (x>0)
	{
		theta = ArcTangent(y/x);
	}
	else if ((x<0) && (y>=0))
	{
		theta = ArcTangent(y/x) + Pi;
	}
	else if ((x<0) && (y<0))
	{
		theta = ArcTangent(y/x) - Pi;
	}
	else if ((x==0) && (y>0))
	{
		theta = 0.5 * Pi;
	}
	else if ((x==0) && (y<0))
	{
		theta = -0.5 * Pi;
	}
	
	// let's return the value
	return theta;		
}