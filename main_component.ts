// src/components/ProjectManagement.tsx
'use client';

import { useState, useEffect } from 'react';
import { ProjectItem, ProjectGroup, CopilotUser } from '@/types';
import { saveItemToCopilot, saveGroupToCopilot } from '@/actions/copilot';

interface ProjectManagementProps {
  initialUserInfo: any;
  initialClients: CopilotUser[];
  initialUsers: CopilotUser[];
  initialFields: any[];
  token?: string;
  userType: string;
}

export default function ProjectManagement({
  initialUserInfo,
  initialClients,
  initialUsers,
  initialFields,
  token,
  userType
}: ProjectManagementProps) {
  const [projects, setProjects] = useState<ProjectItem[]>([]);
  const [groups, setGroups] = useState<ProjectGroup[]>([]);
  const [users, setUsers] = useState<CopilotUser[]>([]);
  const [currentView, setCurrentView] = useState<'table' | 'task' | 'calendar'>('table');
  const [showNewItemModal, setShowNewItemModal] = useState(false);
  const [selectedAssignees, setSelectedAssignees] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [hiddenGroups, setHiddenGroups] = useState<Set<string>>(new Set());

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setIsLoading(true);
      
      // Load project data from custom fields
      const projectFields = initialFields.filter(field => 
        field.name?.startsWith('pm_project_') || 
        field.name?.startsWith('pm_group_')
      );

      const loadedProjects: ProjectItem[] = [];
      const loadedGroups: ProjectGroup[] = [];

      projectFields.forEach(field => {
        try {
          const data = JSON.parse(field.value);
          
          if (field.name?.startsWith('pm_project_')) {
            loadedProjects.push({
              ...data,
              fieldId: field.id
            });
          } else if (field.name?.startsWith('pm_group_')) {
            loadedGroups.push({
              ...data,
              fieldId: field.id
            });
          }
        } catch (error) {
          console.warn('Failed to parse field data:', error);
        }
      });

      // If no data exists, create default structure
      if (loadedGroups.length === 0) {
        const defaultGroups: ProjectGroup[] = [
          {
            id: 'group_current',
            name: 'Current Sprint',
            color: '#003F27',
            collapsed: false,
            createdAt: new Date().toISOString()
          },
          {
            id: 'group_upcoming',
            name: 'Upcoming Tasks',
            color: '#f57c00',
            collapsed: false,
            createdAt: new Date().toISOString()
          }
        ];
        
        setGroups(defaultGroups);
        // Save default groups
        for (const group of defaultGroups) {
          await saveGroupToCopilot(group, token);
        }
      } else {
        setGroups(loadedGroups);
      }

      setProjects(loadedProjects);
      
      // Combine clients and internal users
      const allUsers = [
        ...initialClients.map(client => ({
          id: client.id,
          givenName: client.givenName,
          familyName: client.familyName,
          email: client.email,
          type: 'client' as const
        })),
        ...initialUsers.map(user => ({
          id: user.id,
          givenName: user.givenName,
          familyName: user.familyName,
          email: user.email,
          type: 'internal' as const
        }))
      ];
      
      setUsers(allUsers);
      
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const addProject = async (projectData: Partial<ProjectItem>) => {
    const newProject: ProjectItem = {
      id: `project_${Date.now()}`,
      title: projectData.title || '',
      type: projectData.type || 'task',
      status: projectData.status || 'upcoming',
      assignees: projectData.assignees || [],
      date: projectData.date,
      timelineStart: projectData.timelineStart,
      timelineEnd: projectData.timelineEnd,
      notes: projectData.notes,
      groupId: projectData.groupId || groups[0]?.id || '',
      platform: projectData.platform,
      content: projectData.content,
      socialDatetime: projectData.socialDatetime,
      createdAt: new Date().toISOString()
    };

    setProjects(prev => [...prev, newProject]);
    const result = await saveItemToCopilot(newProject, token);
    
    if (result.success && result.field) {
      setProjects(prev => prev.map(p => 
        p.id === newProject.id 
          ? { ...p, fieldId: result.field.id }
          : p
      ));
    }
    
    setShowNewItemModal(false);
    setSelectedAssignees([]);
  };

  const updateProjectStatus = async (projectId: string, status: string) => {
    const updatedProjects = projects.map(project => 
      project.id === projectId 
        ? { ...project, status: status as ProjectItem['status'] }
        : project
    );
    
    setProjects(updatedProjects);
    
    const updatedProject = updatedProjects.find(p => p.id === projectId);
    if (updatedProject) {
      await saveItemToCopilot(updatedProject, token);
    }
  };

  const toggleGroup = (groupId: string) => {
    const newHiddenGroups = new Set(hiddenGroups);
    if (newHiddenGroups.has(groupId)) {
      newHiddenGroups.delete(groupId);
    } else {
      newHiddenGroups.add(groupId);
    }
    setHiddenGroups(newHiddenGroups);
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return 'No date';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric' 
    });
  };

  const getInitials = (name: string) => {
    if (!name) return '?';
    return name.split(' ').map(word => word[0]).join('').toUpperCase().substring(0, 2);
  };

  const getStatusColor = (status: string) => {
    const colors = {
      'upcoming': '#c4c4c4',
      'in-progress': '#fdab3d',
      'done': '#00c875',
      'stuck': '#e2445c',
      'scheduled': '#003F27'
    };
    return colors[status as keyof typeof colors] || '#c4c4c4';
  };

  const getTypeLabel = (type: string) => {
    const labels = {
      'task': 'Task',
      'social-media': 'Social Media',
      'milestone': 'Milestone'
    };
    return labels[type as keyof typeof labels] || type;
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="text-lg font-medium text-gray-900">Loading Project Management...</div>
          <div className="text-sm text-gray-500 mt-2">Connecting to Copilot.app</div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">Project Management Portal</h1>
            <p className="text-sm text-gray-500">
              Welcome, {initialUserInfo?.givenName} {initialUserInfo?.familyName} 
              ({userType === 'internal' ? 'Internal User' : 'Client'})
            </p>
          </div>
          <button
            onClick={() => setShowNewItemModal(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors"
          >
            + New item
          </button>
        </div>
      </div>

      {/* Toolbar */}
      <div className="bg-white border-b border-gray-200 px-6 py-3">
        <div className="flex items-center space-x-4">
      