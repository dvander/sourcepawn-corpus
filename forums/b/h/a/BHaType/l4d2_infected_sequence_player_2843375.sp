#include <sourcemod>   
#include <sdktools>    
#include <sdkhooks>    

#include <actions>     

enum INextBot {}
enum IBody {}
enum ILocomotion {}


// Activity / animation flags.
// These values are passed into IBody::StartActivity().
enum ActivityType 
{ 
	MOTION_CONTROLLED_XY	= 0x0001,	// Bot XY position and orientation are driven by the animation itself
	MOTION_CONTROLLED_Z		= 0x0002,	// Bot Z position is driven by the animation
	ACTIVITY_UNINTERRUPTIBLE= 0x0004,	// Activity cannot be interrupted until the animation finishes
	ACTIVITY_TRANSITORY		= 0x0008,	// Temporary short animation that plays over the base one, then returns
	ENTINDEX_PLAYBACK_RATE	= 0x0010,	// Playback rate depends on entindex
};


Handle g_hMyNextBotPointer,        // CBaseEntity::MyNextBotPointer
	   g_hGetBodyInterface,       // INextBot::GetBodyInterface
	   g_hStartActivity,          // IBody::StartActivity
	   g_hLookupActivity;         // CBaseAnimating::LookupActivity


// methodmap built on top of BehaviorAction.
// We create our own action type, InfectedActivityPlayer, which can store an activity name.
methodmap InfectedActivityPlayer < BehaviorAction
{
    // Constructor for the custom action.
    // Receives the activity name as input, for example "ACT_TERROR_IDLE_ACQUIRE".
    public InfectedActivityPlayer(const char[] activity)
    {
        // Create a new BehaviorAction named "InfectedActivityPlayer".
        BehaviorAction action = ActionsManager.Create("InfectedActivityPlayer");

        // Assign lifecycle callbacks for this action.
        action.OnStart = InfectedActivityPlayer_OnStart;
        action.OnAnimationActivityComplete = InfectedActivityPlayer_OnAnimationActivityComplete;
        action.OnAnimationActivityInterrupted = InfectedActivityPlayer_OnAnimationActivityInterrupted;

        // Store the activity string inside the action's user-data,
        // so we can read it later in OnStart.
        action.SetUserDataString("m_sActivity", activity);

        // Return the created action cast to our methodmap type.
        return view_as<InfectedActivityPlayer>(action);
    }

    // Helper method: retrieve the stored activity name from user-data.
    public void GetActivity(char[] buffer, int length)
    {
        this.GetUserDataString("m_sActivity", buffer, length);
    }
};


// Per-entity flag for infected:
// true  -> play the animation on the next InfectedWander update
// false -> do nothing
bool g_play_animation[2048 + 1];

public void OnPluginStart()
{
	SetupSDKCalls();
	RegConsoleCmd("sm_play_infected_activity", sm_play_infected_activity);
}


Action sm_play_infected_activity(int client, int args)
{
	int entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		// Mark each infected:
		// when its action updates, we will force it to play the activity.
		g_play_animation[entity] = true;		
	}

	return Plugin_Handled;
}


// When an entity is destroyed, clear its flag,
// so there is no stale data left for a reused entity index.
public void OnEntityDestroyed(int entity)
{
	if (entity > 0 && entity <= 2048)
		g_play_animation[entity] = false;
}


// Hook called when an action is created.
// Here we watch for the standard "InfectedWander" action
// and replace its Update function with our own.
public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
	// If the game created the normal common infected wandering action...
	if (strcmp(name, "InfectedWander") == 0)
	{
		// Hook its Update callback.
		// From now on, every InfectedWander update goes through our function.
		action.Update = InfectedWander_Update;
	}	
}


// Custom Update handler for InfectedWander.
// This is called repeatedly while the infected is running its wander behavior.
public Action InfectedWander_Update(BehaviorAction action, int actor, BehaviorAction priorAction, ActionDesiredResult result)
{
    // If this infected was marked to play an animation...
    if (g_play_animation[actor])
    {
		// ...clear the flag so it only happens once.
		g_play_animation[actor] = false;

        // Suspend the current action and run our custom action instead.
        // The custom action will start the specified animation/activity.
        return action.SuspendFor(InfectedActivityPlayer("ACT_TERROR_IDLE_ACQUIRE"));
    }

	// Otherwise, continue normal behavior.
	return Plugin_Continue;
}


// Called when our custom InfectedActivityPlayer action starts.
public Action InfectedActivityPlayer_OnStart(InfectedActivityPlayer action, int actor, BehaviorAction priorAction, ActionResult result)
{
    // Buffer to store the activity name previously saved in the action.
    char sActivity[64];

    // Read the activity string from action user-data.
    action.GetActivity(sActivity, sizeof sActivity);

	// Convert the activity name string into a numeric activity ID for this entity.
	int activity = LookupActivity(actor, sActivity);

	// If the activity name is invalid or not found, end the action immediately.
	if (activity == -1)
		return action.Done("Invalid activity");

	// Get the entity's INextBot pointer.
	INextBot bot = MyNextBotPointer(actor);

	// From INextBot, get the IBody interface.
	IBody body = GetBodyInterface(bot);

	// Start playing the activity on the bot body.
	StartActivity(body, activity);
	return Plugin_Continue;
}

// Called when the animation/activity finishes successfully.
public Action InfectedActivityPlayer_OnAnimationActivityComplete(BehaviorAction action, int actor, int activity, ActionDesiredResult result)
{
	// End the action with a success reason.
	return action.Done("Animation completed");
}


// Called if the animation/activity gets interrupted by something else.
public Action InfectedActivityPlayer_OnAnimationActivityInterrupted(BehaviorAction action, int actor, int activity, ActionDesiredResult result)
{
	// Ask the behavior system to try sustaining/recovering the action.
	return action.TryToSustain(RESULT_TRY, "Something interrupted us");
}


// ====================================================================================================
// STOCKS
// ====================================================================================================

stock INextBot MyNextBotPointer(int entity)
{
	return SDKCall(g_hMyNextBotPointer, entity);
} 

stock IBody GetBodyInterface(INextBot nextbot)
{
	return SDKCall(g_hGetBodyInterface, nextbot);
} 

stock bool StartActivity(IBody body, int activity, ActivityType flags = MOTION_CONTROLLED_XY)
{
	return SDKCall(g_hStartActivity, body, activity, flags);
} 

stock int LookupActivity(int entity, const char[] activity)
{
	return SDKCall(g_hLookupActivity, entity, activity);
} 

// ====================================================================================================
// SDK SETUP
// ====================================================================================================

void SetupSDKCalls()
{
	GameData data = new GameData("l4d2_infected_stumble");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hMyNextBotPointer = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "INextBot::GetBodyInterface");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hGetBodyInterface = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "IBody::StartActivity");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hStartActivity = EndPrepSDKCall();
	
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CBaseAnimating::LookupActivity");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hLookupActivity = EndPrepSDKCall();

	delete data;

	if (g_hLookupActivity == null)
		SetFailState("CBaseAnimating::LookupActivity signature broken");
}