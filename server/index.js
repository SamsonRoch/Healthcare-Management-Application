const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const bodyParser = require('body-parser');
const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Firebase Admin with your service account
// You'll need to create a serviceAccountKey.json file with your Firebase credentials
try {
  admin.initializeApp({
    credential: admin.credential.cert(require('./serviceAccountKey.json'))
  });
  console.log('Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
}

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Health check endpoint
app.get('/', (req, res) => {
  res.status(200).json({ status: 'Server is running' });
});

// Endpoint for creating staff users (doctors, nurses, receptionists)
app.post('/api/create-staff', async (req, res) => {
  try {
    const { email, password, name, role, phoneNumber, specialty, licenseNumber } = req.body;
    
    // Validate required fields
    if (!email || !password || !name || !role) {
      return res.status(400).json({ 
        success: false, 
        message: 'Missing required fields' 
      });
    }
    
    // Validate role
    const validRoles = ['doctor', 'nurse', 'receptionist', 'admin'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid role. Must be one of: ' + validRoles.join(', ')
      });
    }
    
    // Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name
    });
    
    // Set custom claims for role-based access
    await admin.auth().setCustomUserClaims(userRecord.uid, { role: role });
    
    // Create user document in Firestore
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      id: userRecord.uid,
      email: email,
      name: name,
      role: role,
      phoneNumber: phoneNumber || '',
      specialty: specialty || '',
      licenseNumber: licenseNumber || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true
    });
    
    res.status(200).json({ 
      success: true, 
      message: 'Staff member created successfully',
      uid: userRecord.uid
    });
  } catch (error) {
    console.error('Error creating staff member:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to create staff member',
      error: error.message
    });
  }
});

// Endpoint for updating staff status (active/inactive)
app.patch('/api/staff/:userId/status', async (req, res) => {
  try {
    const { userId } = req.params;
    const { isActive } = req.body;
    
    if (isActive === undefined) {
      return res.status(400).json({
        success: false,
        message: 'isActive status is required'
      });
    }
    
    // Update user in Firestore
    await admin.firestore().collection('users').doc(userId).update({
      isActive: isActive,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Disable/enable the user in Firebase Auth
    await admin.auth().updateUser(userId, {
      disabled: !isActive
    });
    
    res.status(200).json({
      success: true,
      message: `Staff member ${isActive ? 'activated' : 'deactivated'} successfully`
    });
  } catch (error) {
    console.error('Error updating staff status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update staff status',
      error: error.message
    });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});