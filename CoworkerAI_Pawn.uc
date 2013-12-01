class CoworkerAI_Pawn extends UTPawn
  placeable;
   
var(NPC) SkeletalMeshComponent NPCMesh;
var(NPC) class<AIController> NPCController;

simulated event PostBeginPlay()
{
  if(NPCController != none)
  {
    //set the existing ControllerClass to our new NPCController class
    ControllerClass = NPCController;
  }
   
  Super.PostBeginPlay();
}

//override to do nothing
simulated function SetCharacterClassFromInfo(class<UTFamilyInfo> Info)
{
}

defaultproperties
{
  //Setup default NPC mesh
  Begin Object Class=SkeletalMeshComponent Name=NPCMesh0
    SkeletalMesh=SkeletalMesh'Coworker.walkAnim'//SkeletalMesh'Coworker.1'
    PhysicsAsset=PhysicsAsset'Coworker.walkAnim_Physics'//PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
    AnimSets(0)=AnimSet'coworker.m_RogerPelvis' //AnimSet'Coworker.Bip001'
    AnimtreeTemplate=AnimTree'Coworker.AnimTree'
  End Object
  Components.Add(NPCMesh0)

  NPCController=class'CoworkerAI'
  SuperHealthMax=300
  HealthMax=300
  GroundSpeed=165
}