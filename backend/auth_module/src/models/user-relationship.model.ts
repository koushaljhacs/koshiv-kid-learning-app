/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/models/user-relationship.model.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial UserRelationship model — mapping to auth_schema.user_relationships table
 *
 * Aim: User Relationship TypeScript Interface
 * Why: Maps exactly to auth_schema.user_relationships table.
 *      Many-to-many junction linking students to guardians (parents, teachers).
 *      One child can have multiple guardians; one guardian can manage multiple children.
 *      is_primary flag identifies main contact for notifications and recovery.
 *      relationship_type enables personalized communication (mother, father, teacher).
 * ============================================================
 */

export type RelationshipType = 'mother' | 'father' | 'teacher' | 'custodian';

export interface UserRelationship {
  relationship_id: string;
  student_id: string;
  guardian_id: string;
  relationship_type: RelationshipType;
  is_primary: boolean;
  created_at: string;
}

export interface CreateUserRelationship {
  student_id: string;
  guardian_id: string;
  relationship_type: RelationshipType;
  is_primary?: boolean;
}