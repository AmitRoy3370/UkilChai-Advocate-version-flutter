import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'advocate_join_request_dto_model.dart';
import '../LogInPage/LogIn.dart';
import '../CaseRelatedPages/AttachmentViewer.dart'; // 👈 Import the viewer

class AdvocateJoinRequestDetailsPage extends StatelessWidget {
  final AdvocateJoinRequestDTO request;

  const AdvocateJoinRequestDetailsPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Join Request Details"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 12),
                  Text(
                    "Registration Successful!",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your join request has been submitted. Please wait for admin approval.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.green[900],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personal Info
            _buildSectionTitle("Personal Information"),
            _buildCard([
              _buildRow("Name", request.userName ?? 'N/A'),
              _buildRow("Full Name", request.fullName ?? 'N/A'),
              _buildRow("Email", request.email ?? 'N/A'),
              _buildRow("Phone", request.phone ?? 'N/A'),
              _buildRow("District", request.district ?? 'N/A'),
              _buildRow("Location", request.locationName ?? 'N/A'),
            ]),
            const SizedBox(height: 20),

            // Advocate Info
            _buildSectionTitle("Advocate Information"),
            _buildCard([
              _buildRow("Specialities", request.advocateSpeciality.join(', ')),
              _buildRow("Experience", "${request.experience} years"),
              _buildRow("License Key", request.licenseKey ?? 'N/A'),
              _buildRow("Degrees", request.degrees.join(', ')),
              _buildRow("Working Exp. Summary", request.workingExperiences.join(', ')),
            ]),
            const SizedBox(height: 20),

            // Working Experience Details
            if (request.workingExperience != null) ...[
              _buildSectionTitle("Working Experience Details"),
              _buildCard([
                _buildRow("Bar Association", request.workingExperience!.barAssociation ?? 'N/A'),
                _buildRow("Enrolment", request.workingExperience!.barControllEnrolment ?? 'N/A'),
                _buildRow("Primary Practice", request.workingExperience!.primaryPractice ?? 'N/A'),
                _buildRow("Current Chamber", request.workingExperience!.currentChemberName),
                _buildRow("Practice Years", "${request.workingExperience!.yearOfLegalPractice}"),
              ]),
              const SizedBox(height: 20),
            ],

            // Additional Info
            if (request.additionalInfo != null) ...[
              _buildSectionTitle("Additional Information"),
              _buildCard([
                _buildRow("NID Number", request.additionalInfo!.nidNumber ?? 'N/A'),
                _buildRow("Address", request.additionalInfo!.parmanentAdress ?? 'N/A'),
                _buildRow("City", request.additionalInfo!.cityOfUpozila ?? 'N/A'),
                _buildRow("WhatsApp", request.additionalInfo!.whatsAppNumber ?? 'N/A'),
              ]),
              const SizedBox(height: 20),
            ],

            // Documents
            if (request.documents != null && request.documents!.attachments.isNotEmpty) ...[
              _buildSectionTitle("Uploaded Documents"),
              _buildCard([
                for (var doc in request.documents!.attachments)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              title: const Text("Document Viewer"),
                            ),
                            // 👈 Using the CaseAttachmentView widget here
                            body: CaseAttachmentView(
                              attachmentId: doc,
                              jwtToken: '', // Passing empty token since this is before login
                            ),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              doc, 
                              style: const TextStyle(
                                fontSize: 13, 
                                color: Colors.blue, 
                                decoration: TextDecoration.underline
                              )
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
              ]),
            ],

            const SizedBox(height: 30),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}