#if defined _natives_TF2HudMsg
 #endinput
#endif
#define _natives_TF2HudMsg

#include <sourcemod>
#include "morecolors.inc"
#include <tf2_stocks>

#include "tf2hudmsg.inc"

// Some usefull links:
// all dumps: https://github.com/powerlord/tf2-data
// annotations: https://forums.alliedmods.net/showthread.php?p=1946768
//   tf_hud_annotationspanel.cpp <- These use EditablePanel, so can use #LocalizationKeys
// hudnotifycustom: https://forums.alliedmods.net/showthread.php?t=155911

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = {
	name = "[TF2] Hud Msg",
	author = "reBane",
	description = "Providing natives for some Hud Elements and managing Cursor Annotation indices",
	version = "23w45b",
	url = "N/A"
}

public void OnPluginStart() {
	updateAnnotationsMapchange();
	HookEventEx("show_annotation", Event_ShowAnnotation);
	HookEventEx("hide_annotation", Event_ShowAnnotation);
}


public void OnMapEnd() {
	updateAnnotationsMapchange();
}

#define MAX_ANNOTATION_COUNT 2048

enum struct AnnotationData {
	int followEntity;
	bool idUsed;
	float pos[3];
	float lifetime;
	float timeoutestimate; // the time where this annotation will be timed out (through lifetime after Send)
	bool autoclose; //automatically reset the idused state after timeoutestimate or hide -> fire and forget
	int visibilityPartition[4]; //manual target filtering
	char text[MAX_ANNOTATION_LENGTH];
	bool isDeployed;
	any plugindata;
	bool showDistance;
	int playTick; //used to dirty check if an annotation was played by us
	
	void VisibleFor(int client, bool visible=true) {
		int partition = client / 32;
		int bitfieldBit = (1<<(client%32));
		if (visible) {
			this.visibilityPartition[partition] |= bitfieldBit;
		} else {
			this.visibilityPartition[partition] &=~ bitfieldBit;
		}
	}
	void SetText(const char[] text) {
		strcopy(this.text, MAX_ANNOTATION_LENGTH, text);
	}
	void SetParent(int entity) {
		if (!IsValidEdict(entity)) this.followEntity = INVALID_ENT_REFERENCE;
		else {
			// value outside entity limits means, that this is probably already an entref
			this.followEntity = (0 <= entity < 4096) ? EntIndexToEntRef(entity) : entity;
		}
	}
	bool IsPlaying() {
		if (!this.idUsed || !this.isDeployed) return false;
		if (this.lifetime < 0) return true;
		if (this.timeoutestimate <= GetGameTime()) {
			if (this.autoclose) this.idUsed = false;
			this.isDeployed = false;
		}
		return this.isDeployed;
	}
	bool WillBeVisible() {
		return this.visibilityPartition[0] != 0 || this.visibilityPartition[1] != 0 ||
			this.visibilityPartition[2] != 0 || this.visibilityPartition[3] != 0;
	}
	/** @return true if the annotaion was sent to clients */
	bool Send(int selfIndex, const char[] sound, bool showEffect = false) {
		//always update, but don't send if already hidden and nobody sees this
		if (!this.isDeployed && !this.WillBeVisible()) return false;
		Event event = CreateEvent("show_annotation");
		if (event == INVALID_HANDLE) return false;
		event.SetFloat("worldPosX", this.pos[0]);
		event.SetFloat("worldPosY", this.pos[1]);
		event.SetFloat("worldPosZ", this.pos[2]);
		event.SetFloat("lifetime", this.lifetime);
		event.SetInt("id", selfIndex);
		if (!strlen(this.text)) //prevent default *AnnotationPannel_Callout
			event.SetString("text", " ");
		else
			event.SetString("text", this.text);
		event.SetString("play_sound", sound);
		if (this.followEntity != INVALID_ENT_REFERENCE) event.SetInt("follow_entindex", EntRefToEntIndex(this.followEntity));
		if (showEffect) event.SetBool("show_effect", showEffect);
		if (this.showDistance) event.SetBool("show_distance", this.showDistance);
		this.timeoutestimate = (this.lifetime > 0.0) ? (GetGameTime() + this.lifetime) : 0.0;
		this.playTick = GetGameTickCount();
		if (MaxClients > 32) {
			//use "all", as we send to single clients anyways, FireToClient does not hook either
			event.SetInt("visibilityBitfield", 0xFFFFFFFF);
			for (int client=1; client <= MaxClients; client++) {
				if ((this.visibilityPartition[client/32] & (1<<(client%32)))!=0 && IsClientInGame(client)) {
					event.FireToClient(client);
				}
			}
			event.Close();
		} else {
			//create lowest partition as legacy bitfield
			int bits = this.visibilityPartition[0] | (this.visibilityPartition[1] & 1);
			event.SetInt("visibilityBitfield", bits);
			event.Fire();
		}
		return true;
	}
	/** @return true if the annotation is hidden after call */
	bool Hide(int selfIndex) {
		if (!this.isDeployed) return true;
		Event event = CreateEvent("hide_annotation");
		if (event == INVALID_HANDLE) return false;
		event.SetInt("id", selfIndex);
		event.Fire();
		this.isDeployed = false;
		if (this.autoclose) this.idUsed = false;
		return true;
	}
}
AnnotationData annotations[MAX_ANNOTATION_COUNT];
any Impl_CursorAnnotation_new(int index = -1, bool reset=false) {
	if (index < 0) {
		//find free index
		for (int i;i<MAX_ANNOTATION_COUNT;i++) {
			if (!annotations[i].idUsed) {
				index = i;
				break;
			} else if (annotations[i].autoclose && annotations[i].lifetime >= 0.0 && annotations[i].timeoutestimate <= GetGameTime()) {
				annotations[i].idUsed = false;
				index = i;
				break;
			}
		}
	}
	if (index < 0 || index >= MAX_ANNOTATION_COUNT) {
		return -1;
	}
	if (!annotations[index].idUsed || reset) {
		float zero[3];
		//default visible to all
		annotations[index].visibilityPartition[0] = 0xFFFFFFFE;
		annotations[index].visibilityPartition[1] = 0xFFFFFFFF;
		annotations[index].visibilityPartition[2] = 0xFFFFFFFF;
		annotations[index].visibilityPartition[3] = 0xFFFFFFFF;
		annotations[index].followEntity = INVALID_ENT_REFERENCE;
		annotations[index].lifetime = 10.0;
		annotations[index].SetText("< ERROR >");
		annotations[index].pos = zero;
		annotations[index].idUsed = true;
		annotations[index].autoclose = false;
		annotations[index].showDistance = false;
		annotations[index].plugindata = 0;
		if (annotations[index].isDeployed) {
			annotations[index].Hide(index);
		}
	}
	return index;
}

public void Event_ShowAnnotation(Event event, const char[] name, bool dontBroadcast) {
	int index = event.GetInt("id");
	if (index < 0 || index >= MAX_ANNOTATION_COUNT) return; //we can't track this
	if (name[0] == 's') {
		annotations[index].isDeployed = true;
		if (annotations[index].idUsed && annotations[index].playTick == GetGameTickCount()) {
			return; //we know this is our event
		}
		//import with legacy behaviour, bit 0 should always be 0 as it can't be updated later
		annotations[index].visibilityPartition[1] = event.GetInt("visibilityBitfield", 0xFFFFFFFF);
		annotations[index].visibilityPartition[2] = annotations[index].visibilityPartition[1];
		annotations[index].visibilityPartition[3] = annotations[index].visibilityPartition[1];
		annotations[index].visibilityPartition[0] = (annotations[index].visibilityPartition[1] & 0xFFFFFFFE);
		int ent = event.GetInt("follow_entindex");
		if (ent>=0 && IsValidEntity(ent)) ent = EntIndexToEntRef(ent);
		else ent = INVALID_ENT_REFERENCE;
		annotations[index].followEntity = ent;
		event.GetString("text", annotations[index].text, MAX_ANNOTATION_LENGTH, "< ERROR >");
		annotations[index].pos[0] = event.GetFloat("worldPosX");
		annotations[index].pos[1] = event.GetFloat("worldPosY");
		annotations[index].pos[2] = event.GetFloat("worldPosZ");
		annotations[index].idUsed = true;
		annotations[index].autoclose = false;
		annotations[index].showDistance = event.GetBool("show_distance");
		annotations[index].lifetime = event.GetFloat("lifetime");
		annotations[index].timeoutestimate = (annotations[index].lifetime > 0) ? (GetGameTime() + annotations[index].lifetime) : 0.0;
		annotations[index].plugindata = 0;
	} else {
		annotations[index].isDeployed = false;
	}
}


void updateAnnotationsMapchange() {
	for (int i;i<MAX_ANNOTATION_COUNT;i++) {
		annotations[i].timeoutestimate = 0.0;
		annotations[i].isDeployed = false;
		if (annotations[i].autoclose)
			annotations[i].idUsed = false;
	}
}

/**
 * Displays a HudNotification (centered, bottom half) for the client
 * This element will NOT show with minimal hud!
 * https://forums.alliedmods.net/showthread.php?t=155911
 * @param icon taken from mod_textures.txt
 * @param background (Use a TFTeam or -1 for client team color)
 * @param message (+ format)
 */
void Impl_HudNotificationCustom(int client, const char[] icon="voice_self", int background=-1, bool stripMoreColors=false, const char[] message) {
	if (!IsClientInGame(client) || IsFakeClient(client)) return;
	
	char msg[MAX_MESSAGE_LENGTH];
	strcopy(msg, sizeof(msg), message);
	if (stripMoreColors) CReplaceColorCodes(msg, client, true, sizeof(msg));
	ReplaceString(msg,sizeof(msg),"\"","'");
	if (background < 0) background = view_as<int>(TF2_GetClientTeam(client));
	
	Handle hdl = StartMessageOne("HudNotifyCustom", client);
	BfWriteString(hdl, msg);
	BfWriteString(hdl, icon);
	BfWriteByte(hdl, background);
	EndMessage();
}

// --== NATIVES ==--

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("CursorAnnotation.CursorAnnotation",     Native_CursorAnnotation_new);
	CreateNative("CursorAnnotation.Close",                Native_CursorAnnotation_Close);
	CreateNative("CursorAnnotation.IsValid.get",          Native_CursorAnnotation_IsValid_Get);
	CreateNative("CursorAnnotation.SetVisibilityFor",     Native_CursorAnnotation_SetVisibilityFor);
	CreateNative("CursorAnnotation.SetVisibilityAll",     Native_CursorAnnotation_SetVisibilityAll);
	CreateNative("CursorAnnotation.VisibilityBitmask.get",Native_CursorAnnotation_VisibilityBitmask_Get);
	CreateNative("CursorAnnotation.VisibilityBitmask.set",Native_CursorAnnotation_VisibilityBitmask_Set);
	CreateNative("CursorAnnotation.ShowDistance.get",     Native_CursorAnnotation_ShowDistance_Get);
	CreateNative("CursorAnnotation.ShowDistance.set",     Native_CursorAnnotation_ShowDistance_Set);
	CreateNative("CursorAnnotation.Data.get",             Native_CursorAnnotation_Data_Get);
	CreateNative("CursorAnnotation.Data.set",             Native_CursorAnnotation_Data_Set);
	CreateNative("CursorAnnotation.SetText",              Native_CursorAnnotation_SetText);
	CreateNative("CursorAnnotation.SetPosition",          Native_CursorAnnotation_SetPosition);
	CreateNative("CursorAnnotation.GetPosition",          Native_CursorAnnotation_GetPosition);
	CreateNative("CursorAnnotation.SetLifetime",          Native_CursorAnnotation_SetLifetime);
	CreateNative("CursorAnnotation.ParentEntity.get",     Native_CursorAnnotation_ParentEntity_Get);
	CreateNative("CursorAnnotation.ParentEntity.set",     Native_CursorAnnotation_ParentEntity_Set);
	CreateNative("CursorAnnotation.IsPlaying.get",        Native_CursorAnnotation_IsPlaying_Get);
	CreateNative("CursorAnnotation.AutoClose.get",        Native_CursorAnnotation_AutoClose_Get);
	CreateNative("CursorAnnotation.AutoClose.set",        Native_CursorAnnotation_AutoClose_Set);
	CreateNative("CursorAnnotation.Update",               Native_CursorAnnotation_Update);
	CreateNative("CursorAnnotation.Hide",                 Native_CursorAnnotation_Hide);
	CreateNative("TF2_HudNotificationCustom",             Native_TF2_HudNotificationCustom);
	CreateNative("TF2_HudNotificationCustomAll",          Native_TF2_HudNotificationCustomAll);
	CreateNative("EscapeVGUILocalization",                Native_EscapeVGUILocalization);
	RegPluginLibrary("tf2hudmsg");
	return APLRes_Success;
}

bool Helper_ValidIndex(int index, bool checkUsed=true) {
	if (index < 0 || index >= MAX_ANNOTATION_COUNT)
		ThrowNativeError(SP_ERROR_INDEX, "Invalid CursorAnnotation", index);
	else if (checkUsed && !annotations[index].idUsed)
		ThrowNativeError(SP_ERROR_INDEX, "The cursor annotation (%i) is closed", index);
	else return true;
	return false;
}

public any Native_CursorAnnotation_new(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	bool reset = view_as<bool>(GetNativeCell(2));
	
	return Impl_CursorAnnotation_new(index, reset);
}
public any Native_CursorAnnotation_Close(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	
	annotations[index].Hide(index);
	annotations[index].idUsed = false;
	return 0;
}
public any Native_CursorAnnotation_IsValid_Get(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	
	return index>=0 && index<MAX_ANNOTATION_COUNT && annotations[index].idUsed;
}
public any Native_CursorAnnotation_SetVisibilityFor(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	
	int client = view_as<int>(GetNativeCell(2));
	bool visible = view_as<bool>(GetNativeCell(3));
	
	annotations[index].VisibleFor(client, visible);
	return 0;
}
public any Native_CursorAnnotation_SetVisibilityAll(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	bool visible = view_as<bool>(GetNativeCell(2));
	
	int newvalue = (visible) ? 0xFFFFFFFF : 0;
	annotations[index].visibilityPartition[0] = (newvalue & 0xFFFFFFFE); //we have player index 32 in the next partition
	annotations[index].visibilityPartition[1] = newvalue;
	annotations[index].visibilityPartition[2] = newvalue;
	annotations[index].visibilityPartition[3] = newvalue;
	return 0;
}
public any Native_CursorAnnotation_VisibilityBitmask_Get(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	//construct legacy bitmask
	return annotations[index].visibilityPartition[0] | (annotations[index].visibilityPartition[1] & 1);
}
public any Native_CursorAnnotation_VisibilityBitmask_Set(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	int value = view_as<int>(GetNativeCell(2));
	//set from bitmask with legacy behaviour
	annotations[index].visibilityPartition[0] = (value & 0xFFFFFFFE); //we have player index 32 in the next partition
	annotations[index].visibilityPartition[1] = value;
	annotations[index].visibilityPartition[2] = value;
	annotations[index].visibilityPartition[3] = value;
	return 0;
}
public any Native_CursorAnnotation_ShowDistance_Get(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	
	return annotations[index].showDistance;
}
public any Native_CursorAnnotation_ShowDistance_Set(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	any value = GetNativeCell(2);
	
	annotations[index].showDistance = value != 0;
	return 0;
}
public any Native_CursorAnnotation_Data_Get(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	
	return annotations[index].plugindata;
}
public any Native_CursorAnnotation_Data_Set(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	any value = GetNativeCell(2);
	
	annotations[index].plugindata = value;
	return 0;
}
public any Native_CursorAnnotation_SetText(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	int len;
	GetNativeStringLength(2,len);
	char[] text = new char[len+1];
	GetNativeString(2, text, len+1);
	
	if (StrEqual(annotations[index].text, text)) return false;
	annotations[index].SetText(text);
	return true;
}
public any Native_CursorAnnotation_SetPosition(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	float vec[3];
	GetNativeArray(2,vec,sizeof(vec));
	
	annotations[index].pos = vec;
	return 0;
}
public any Native_CursorAnnotation_GetPosition(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	float vec[3];
	
	vec = annotations[index].pos;
	SetNativeArray(2,vec,sizeof(vec));
	return 0;
}
public any Native_CursorAnnotation_SetLifetime(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	float lifetime = view_as<float>(GetNativeCell(2));
	
	annotations[index].lifetime = lifetime;
	return 0;
}
public any Native_CursorAnnotation_ParentEntity_Get(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	
	return annotations[index].followEntity;
}
public any Native_CursorAnnotation_ParentEntity_Set(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	int entity = view_as<int>(GetNativeCell(2));
	
	annotations[index].SetParent(entity);
	return 0;
}
public any Native_CursorAnnotation_IsPlaying_Get(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index, false)) return 0;
	
	return annotations[index].IsPlaying();
}
public any Native_CursorAnnotation_AutoClose_Get(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	
	return annotations[index].autoclose;
}
public any Native_CursorAnnotation_AutoClose_Set(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	bool value = view_as<bool>(GetNativeCell(2));
	
	return annotations[index].autoclose = value;
}
public any Native_CursorAnnotation_Update(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index)) return 0;
	int len;
	GetNativeStringLength(2,len);
	char[] sound = new char[len+1];
	GetNativeString(2,sound,len+1);
	bool effect = view_as<bool>(GetNativeCell(3));
	
	annotations[index].Send(index, sound, effect);
	return 0;
}
public any Native_CursorAnnotation_Hide(Handle plugin, int argc) {
	int index = view_as<int>(GetNativeCell(1));
	if (!Helper_ValidIndex(index, false)) return 0;
	
	annotations[index].Hide(index);
	return 0;
}

//native void TF2_HudNotificationCustom(int client, const char[] icon="voice_self", int background=-1, bool stripMoreColors=false, const char[] message, any ...);
public any Native_TF2_HudNotificationCustom(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int maxlen;
	GetNativeStringLength(2, maxlen);
	if (maxlen < 0) return 0;
	char[] icon = new char[maxlen+1];
	GetNativeString(2,icon,maxlen+1);
	int background = view_as<int>(GetNativeCell(3));
	bool stripcol = view_as<bool>(GetNativeCell(4));
	char message[MAX_MESSAGE_LENGTH];
	SetGlobalTransTarget(client);
	FormatNativeString(0,5,6,MAX_MESSAGE_LENGTH,_,message,_);
	
	Impl_HudNotificationCustom(client, icon, background, stripcol, message);
	return 0;
}

//native void TF2_HudNotificationCustomAll(const char[] icon="voice_self", int background=-1, bool stripMoreColors=false, const char[] message, any ...);
public any Native_TF2_HudNotificationCustomAll(Handle plugin, int argc) {
	int maxlen;
	GetNativeStringLength(1, maxlen);
	if (maxlen < 0) return 0;
	char[] icon = new char[maxlen+1];
	GetNativeString(1,icon,maxlen+1);
	int background = view_as<int>(GetNativeCell(2));
	bool stripcol = view_as<bool>(GetNativeCell(3));
	char message[MAX_MESSAGE_LENGTH];
	
	for (int i=1;i<=MaxClients;i++) {
		SetGlobalTransTarget(i);
		FormatNativeString(0,4,5,MAX_MESSAGE_LENGTH,_,message,_);
		Impl_HudNotificationCustom(i, icon, background, stripcol, message);
	}
	return 0;
}

//native void EscapeVGUILocalization(char[] buffer, int maxsize);
public any Native_EscapeVGUILocalization(Handle plugin, int argc) {
	if (IsNativeParamNullString(1)) return 0;
	int maxlen = view_as<int>(GetNativeCell(2));
	int inlen;
	char[] buffer = new char[maxlen];
	GetNativeString(1, buffer, maxlen, inlen);
	if (!inlen) return 0; //string is empty, nothing to do
	
	//prevent #LocalizationKeys from being looked up
	// For a localization to be considered, the string MIGHT start with a number sign but they usually
	// don't contain spaces and are ASCII strings
	// Not being a localization does not modify the string but we have no real way to check if this is
	// a localization or not, so let's just prefix it with a space (barely noticable in annotations)
	bool mightkey = true;
	//check if this matches ^#?\w*$
	int i = (buffer[0]=='#')?1:0; // ^#?
	for(; i < maxlen && buffer[i]; i++) { // \w*$
		if (!('a' <= buffer[i] <= 'z' || 'A' <= buffer[i] <= 'Z' || '0' <= buffer[i] <= '9' || buffer[i]=='_' || buffer[i]=='-')) {
			mightkey=false;
			break;
		}
	}
	if (mightkey) {
		//\x1f is the unit separator and does not render, so we can use it as zero-width non-whitespace prefix
		Format(buffer, maxlen, "\x1f%s", buffer);
	}
	//after looking up #LocalizationKeys, source tries to agressively fill %Placeholders
	//those placeholders usually look like %s1 or something, so we need to get rid of the percent symbols
	ReplaceString(buffer, maxlen, "%", "\xEF\xBC\x85"); //the replacement is a "full wide percent"
	
	//alright, let's copy you back where you belong
	SetNativeString(1, buffer, maxlen);
	return 0;
}
