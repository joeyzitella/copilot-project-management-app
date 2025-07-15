# Complete setup commands for your GitHub repository

# 1. Run this in your terminal to create the project:
mkdir copilot-project-management-app
cd copilot-project-management-app
git init

# 2. Create the basic files structure (run the setup script from above first)

# 3. Then create these files with full content:

# === src/actions/copilot.ts ===
cat > src/actions/copilot.ts << 'EOF'
'use server';

import { getCopilotApi } from '@/lib/copilot';
import { unstable_noStore as noStore } from 'next/cache';
import { ProjectItem, ProjectGroup } from '@/types';

export async function getUserInfo(token?: string) {
  noStore();
  
  try {
    if (!token) {
      return {
        userInfo: null,
        userType: 'demo',
        success: false,
        error: 'No session token provided'
      };
    }

    const copilot = getCopilotApi(token);
    
    // Get token payload to determine user type
    const tokenPayload = await copilot.getTokenPayload();
    
    let userInfo = null;
    let userType = 'unknown';
    
    if (tokenPayload.internalUserId) {
      userInfo = {
        id: tokenPayload.internalUserId,
        email: 'internal@company.com',
        givenName: 'Internal',
        familyName: 'User',
        role: 'internal'
      };
      userType = 'internal';
    } else if (tokenPayload.clientId) {
      try {
        const response = await copilot.retrieveClient({ id: tokenPayload.clientId });
        userInfo = response.data;
        userType = 'client';
      } catch (error) {
        userInfo = {
          id: tokenPayload.clientId,
          email: 'client@company.com',
          givenName: 'Client',
          familyName: 'User'
        };
        userType = 'client';
      }
    }
    
    return {
      userInfo,
      userType,
      tokenPayload,
      success: true
    };
  } catch (error) {
    console.error('Failed to get user info:', error);
    return {
      userInfo: null,
      userType: 'demo',
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function getClients(token?: string) {
  noStore();
  
  try {
    if (!token) {
      return { clients: [], success: false, error: 'No token provided' };
    }

    const copilot = getCopilotApi(token);
    const response = await copilot.listClients();
    
    return {
      clients: response.data || [],
      success: true
    };
  } catch (error) {
    console.error('Failed to get clients:', error);
    return {
      clients: [],
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function getInternalUsers(token?: string) {
  noStore();
  
  try {
    if (!token) {
      return { users: [], success: false, error: 'No token provided' };
    }

    const copilot = getCopilotApi(token);
    const response = await copilot.listInternalUsers();
    
    return {
      users: response.data || [],
      success: true
    };
  } catch (error) {
    console.error('Failed to get internal users:', error);
    return {
      users: [],
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function getCustomFields(token?: string) {
  noStore();
  
  try {
    if (!token) {
      return { fields: [], success: false, error: 'No token provided' };
    }

    const copilot = getCopilotApi(token);
    const response = await copilot.listCustomFields();
    
    return {
      fields: response.data || [],
      success: true
    };
  } catch (error) {
    console.error('Failed to get custom fields:', error);
    return {
      fields: [],
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function saveItemToCopilot(item: ProjectItem, token?: string) {
  noStore();
  
  try {
    if (!token) {
      throw new Error('No token provided');
    }

    const copilot = getCopilotApi(token);
    const fieldName = `pm_item_${item.id}`;
    const fieldData = {
      name: fieldName,
      type: 'text' as const,
      value: JSON.stringify(item)
    };

    let response;
    if (item.fieldId) {
      response = await copilot.updateCustomField({
        id: item.fieldId,
        requestBody: fieldData
      });
    } else {
      response = await copilot.createCustomField({
        requestBody: fieldData
      });
    }
    
    return {
      success: true,
      field: response.data
    };
  } catch (error) {
    console.error('Failed to save item:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function saveGroupToCopilot(group: ProjectGroup, token?: string) {
  noStore();
  
  try {
    if (!token) {
      throw new Error('No token provided');
    }

    const copilot = getCopilotApi(token);
    const fieldName = `pm_group_${group.id}`;
    const fieldData = {
      name: fieldName,
      type: 'text' as const,
      value: JSON.stringify(group)
    };

    let response;
    if (group.fieldId) {
      response = await copilot.updateCustomField({
        id: group.fieldId,
        requestBody: fieldData
      });
    } else {
      response = await copilot.createCustomField({
        requestBody: fieldData
      });
    }
    
    return {
      success: true,
      field: response.data
    };
  } catch (error) {
    console.error('Failed to save group:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}
EOF

# === src/app/page.tsx ===
cat > src/app/page.tsx << 'EOF'
import { SearchParams } from '@/types';
import { getUserInfo, getClients, getInternalUsers, getCustomFields } from '@/actions/copilot';
import ProjectManagement from '@/components/ProjectManagement';

export const revalidate = 180; // 3 minutes

export default async function HomePage({ 
  searchParams 
}: { 
  searchParams: SearchParams 
}) {
  const inputToken = searchParams.token;
  const tokenValue = typeof inputToken === 'string' ? inputToken : undefined;

  if (!tokenValue) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">
            Project Management Portal
          </h1>
          <div className="bg-red-50 border border-red-200 rounded-md p-4 max-w-md">
            <p className="text-red-800">
              This app must be accessed through Copilot.app to function properly.
            </p>
            <p className="text-sm text-red-600 mt-2">
              Please embed this app as a Custom App in your Copilot dashboard.
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Get user info first
  const userResult = await getUserInfo(tokenValue);
  
  if (!userResult.success) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">
            Project Management Portal
          </h1>
          <div className="bg-red-50 border border-red-200 rounded-md p-4 max-w-md">
            <p className="text-red-800">
              Failed to authenticate with Copilot.app
            </p>
            <p className="text-sm text-red-600 mt-2">
              Error: {userResult.error}
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Load additional data
  const [clientsResult, usersResult, fieldsResult] = await Promise.all([
    getClients(tokenValue),
    getInternalUsers(tokenValue),
    getCustomFields(tokenValue)
  ]);

  return (
    <ProjectManagement
      initialUserInfo={userResult.userInfo}
      initialClients={clientsResult.clients}
      initialUsers={usersResult.users}
      initialFields={fieldsResult.fields}
      token={tokenValue}
      userType={userResult.userType}
    />
  );
}
EOF

# === src/app/layout.tsx ===
cat > src/app/layout.tsx << 'EOF'
import './globals.css';
import { Inter } from 'next/font/google';

const inter = Inter({ subsets: ['latin'] });

export const metadata = {
  title: 'Project Management - Copilot App',
  description: 'A comprehensive project management tool for Copilot.app',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
EOF

# === src/app/globals.css ===
cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: #f6f7fb;
  color: #323338;
  line-height: 1.4;
}
EOF

echo "✅ All files created!"
echo ""
echo "🚀 Now push to GitHub:"
echo "git add ."
echo "git commit -m 'Initial commit: Copilot Project Management App'"
echo "git remote add origin https://github.com/joeyziztella/copilot-project-management-app.git"
echo "git push -u origin main"
echo ""
echo "🌐 After pushing, connect to a deployment platform!"
