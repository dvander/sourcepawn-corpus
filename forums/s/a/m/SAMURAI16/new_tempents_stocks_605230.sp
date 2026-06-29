/* 						
	Made by SAMURAI 
	
	
Have a nice day now	
*						*/


/**
 * Sets up a beam ents effect
 *
 * @param StartEntity		Start position of the beam.
 * @param EndEntity		End position of the beam.
 * @param ModelIndex		Precached model index.
 * @param HaloIndex		Precached model index.
 * @param StartFrame		Initital frame to render.
 * @param FrameRate		Beam frame rate.
 * @param Life			Time duration of the beam.
 * @param Width			Initial beam width.
 * @param EndWidth		Final beam width.
 * @param FadeLength		Beam fade time duration.
 * @param Amplitude		Beam amplitude.
 * @param color			Color array (r, g, b, a).
 * @param iFlags		beam flags (read sdktools_tempents.inc)
 * @noreturn
 */
stock TE_SetupBeamEnts(StartEntity,EndEntity,ModelIndex,HaloIndex,StartFrame,FrameRate,Float:fLife,Float:fWidth,Float:fEndWidth,FadeLength,Float:fAmplitude,iSpeed,color[4],iFlags)
{
	TE_Start("BeamEnts");
	TE_WriteNum("m_nModelIndex",ModelIndex);
	TE_WriteNum("m_nHaloIndex",HaloIndex);
	TE_WriteNum("m_nStartFrame",StartFrame);
	TE_WriteNum("m_nFrameRate",FrameRate);
	TE_WriteFloat("m_fLife",fLife);
	TE_WriteFloat("m_fWidth",fWidth);
	TE_WriteFloat("m_fEndWidth",fEndWidth);
	TE_WriteNum("m_nFadeLength",FadeLength);
	TE_WriteFloat("m_fAmplitude",fAmplitude);
	TE_WriteNum("m_nSpeed",iSpeed);
	TE_WriteNum("r",color[0]);
	TE_WriteNum("g",color[1]);
	TE_WriteNum("b",color[2]);
	TE_WriteNum("a",color[3]);
	TE_WriteNum("m_nFlags",iFlags);
	TE_WriteNum("m_nStartEntity",StartEntity);
	TE_WriteNum("m_nEndEntity",EndEntity);
}

   
/**
 * Sets up a blood stream effect
 *
 * @param vecOrigin		Position of the Blood stream
 * @param vecDirection		Direction of the blood stream
 * @param color			Color array (r, g, b, a).
 * @param amount		amount
 * @noreturn
 */
stock TE_SetupBloodStream(const Float:vecOrigin[3],const Float:vecDirection[3], color[4], amount)
{
	TE_Start("Blood Stream");
	TE_WriteVector("m_vecOrigin[0]",vecOrigin);
	TE_WriteVector("m_vecDirection",vecDirection);
	TE_WriteNum("r",color[0]);
	TE_WriteNum("g",color[1]);
	TE_WriteNum("b",color[2]);
	TE_WriteNum("a",color[3]);
	TE_WriteNum("m_nAmount",amount);
}


/**
 * Sets up bubbles effect
 *
 * @param vecMins		Mins
 * @param vecMaxs		Maxs
 * @param ModelIndex		Precached model index.
 * @param fHeight		Height ?
 * @param nCount		Count of bubbles
 * @param fSpeed		Speed of bubbles
 * @noreturn
 */
stock TE_SetupBubbles(const Float:vecMins[3], const Float:vecMaxs[3], ModelIndex, Float:fHeight,nCount,Float:fSpeed)
{
	TE_Start("Bubbles");
	TE_WriteVector("m_vecMins",vecMins);
	TE_WriteVector("m_vecMaxs",vecMaxs)
	TE_WriteNum("m_nModelIndex",ModelIndex);
	TE_WriteFloat("m_fHeight",fHeight);
	TE_WriteNum("m_nCount",nCount);
	TE_WriteFloat("m_fSpeed",fSpeed);
}
  

/**
 * Sets up bubble trail effect
 *
 * @param vecMins		Mins
 * @param vecMaxs		Maxs
 * @param ModelIndex		Precached model index.
 * @param fWaterZ		WaterZ ?
 * @param count			Count of bubbles
 * @param fSpeed		Speed of bubbles
 * @noreturn
 */
stock TE_SetupBubbleTrail(const Float:vecMins[3], const Float:vecMaxs[3],ModelIndex,Float:fWaterZ,count,Float:fSpeed)
{
	TE_Start("Bubble Trail");
	TE_WriteVector("m_vecMins",vecMins);
	TE_WriteVector("m_vecMaxs",vecMaxs)
	TE_WriteNum("m_nModelIndex",ModelIndex);
	TE_WriteFloat("m_flWaterZ",fWaterZ);
	TE_WriteNum("m_nCount",count);
	TE_WriteFloat("m_fSpeed",fSpeed);
}
  

/**
 * Sets up a Dynamic Light effect
 *
 * @param vecOrigin		Position of the Dynamic Light
 * @param r			r color value
 * @param g			g color value
 * @param b			b color value
 * @param iExponent		?
 * @param fTime			Duration
 * @param fDecay		Decay of dynamic light
 * @noreturn
 */
stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
	TE_Start("Dynamic Light");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("exponent",iExponent);
	TE_WriteFloat("m_fRadius",fRadius);
	TE_WriteFloat("m_fTime",fTime);
	TE_WriteFloat("m_fDecay",fDecay);
}
	


/**
 * Sets up a Fire Bullets effect
 *
 * @param vecOrigin		Position of the Fire Bullets
 * @param vecAngles		Angles 
 * @param iWeaponID		weapon id
 * @param iMode			?
 * @param iSeed			?
 * @param iPlayer		Player..
 * @param flSpread		Accuracy of the Fire Bullets.
 * @noreturn
 */
stock TE_SetupFireBullets(const Float:vecOrigin[3],const Float:vecAngles[3], iWeaponID, iMode,iSeed,iPlayer,Float:flSpread)
{
	TE_Start("Fire Bullets");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteAngles("m_vecAngles[0]",vecAngles);
	TE_WriteNum("m_iWeaponID",iWeaponID);
	TE_WriteNum("m_iMode",iMode);
	TE_WriteNum("m_iSeed",iSeed);
	TE_WriteNum("m_iPlayer",iPlayer);
	TE_WriteFloat("m_flSpread",flSpread);
}



/**
 * Sets up a Foot Print Decal effect
 *
 * @param vecOrigin		Position of the Foot print decal
 * @param vecDirection		Direction 
 * @param ent			entity
 * @param index			?
 * @param materialType		Foot Print decal material type
 * @noreturn
 */
stock TE_SetupFootPrintDecal(const Float:vecOrigin[3],const Float:vecDirection[3], ent,index,materialType = 'C')
{
	TE_Start("Footprint Decall");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteVector("m_vecDirection",vecDirection);
	TE_WriteNum("m_nEntity",ent);
	TE_WriteNum("m_nIndex",index);
	TE_WriteNum("m_chMaterialType",materialType);
}

  
/**
 * Sets up a Gauss Explosion effect
 *
 * @param vecOrigin		Position of the Fire Bullets
 * @param vecDirection		Direction 
 * @param Type			Gauss Explosion type (mod specific)
 * @noreturn
 */
stock TE_SetupGaussExplosion(const Float:vecOrigin[3],const Float:vecDirection[3], Type)
{
	TE_Start("GaussExplosion");
	TE_WriteVector("m_vecOrigin[0]",vecOrigin);
	TE_WriteNum("m_nType",Type);
	TE_WriteVector("m_vecDirection",vecDirection);
}



/**
 * Sets up Kill player Attachments
 *
 * @param player		Specific player
 * @noreturn
 */
stock TE_SetupKillPlayerAttachments(player)
{
	TE_Start("KillPlayerAttachments");
	TE_WriteNum("m_nPlayer",player);
}


/**
 * Sets up a Large Funnel Effect
 *
 * @param vecOrigin		Position of the Large Funnel
 * @param ModelIndex		Precached model index. 
 * @param reversed		?
 * @noreturn
 */   
stock TE_SetupLargeFunnel(const Float:vecOrigin[3], modelIndex, reversed)
{
	TE_Start("Large Funnel");
	TE_WriteVector("m_vecOrigin[0]",vecOrigin);
	TE_WriteNum("m_nModelIndex",modelIndex);
	TE_WriteNum("m_nReversed",reversed);
}

  
/**
 * Sets up Player Animation Event
 *
 * @param player		Specific player
 * @param event			Specific event 
 * @noreturn
 */  
stock TE_SetupPlayerAnimEvent(player,event)
{
	TE_Start("PlayerAnimEvent");
	TE_WriteNum("m_hPlayer",player);
	TE_WriteNum("m_iEvent",event);
}
	

  
/**
 * Sets up a BSP Decal effect
 *
 * @param vecOrigin		Position of the BSP Decal
 * @param entity		entity
 * @param index			? 
 * @noreturn
 */
stock TE_SetupBSPDecal(const Float:vecOrigin[3], entity, index)
{
	TE_Start("BSP Decal");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("m_nEntity",entity);
	TE_WriteNum("m_nIndex",index);
}



/**
 * Sets up a Plant Bomb Effect
 *
 * @param vecOrigin		Position of the Plant bomb
 * @param player		Bomb owner (guess)
 * @noreturn
 */   
stock TE_SetupPlantBomb(const Float:vecOrigin[3], player)
{
	TE_Start("Bomb Plant");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("m_iPlayer",player);
}



/**
 * Sets up a Player Decal
 *
 * @param vecOrigin		Position of the Player Decal
 * @param entity		entity
 * @param player		Specific player
 * @noreturn
 */ 
stock TE_SetupPlayerDecal(const Float:vecOrigin[3], entity, player)
{
	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("m_nEntity",entity);
	TE_WriteNum("m_nPlayer",player);
}



/**
 * Sets up a Project Decal
 *
 * @param vecOrigin		Position of the Project Decal
 * @param angRotation		Angle rotation
 * @param flDistance		Distance
 * @param index			?
 * @noreturn
 */ 
stock TE_SetupProjectedDecal(const Float:vecOrigin[3], const Float:angRotation[3], Float:flDistance, index)
{
	TE_Start("Projected Decal");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteAngles("m_angRotation",angRotation);
	TE_WriteFloat("m_flDistance",flDistance);
	TE_WriteNum("m_nIndex",index);
}


/**
 * Sets up a Radio Icon effect
 *
 * @param AttachToClient		What you attach to client
 * @noreturn
 */ 
stock TE_SetupRadioIcon(AttachToClient)
{
	TE_Start("RadioIcon");
	TE_WriteNum("m_iAttachToClient",AttachToClient);
}


/**
 * Sets up a Show Line effect
 *
 * @param vecOrigin		Position of the Show line
 * @param vecEnd		End position of show line
 * @noreturn
 */ 
stock TE_SetupShowLine(const Float:vecOrigin[3], const Float:vecEnd[3])
{
	TE_Start("Show Line");
	TE_WriteVector("m_vecOrigin[0]",vecOrigin);
	TE_WriteVector("m_vecEnd",vecEnd);
}
	
	
