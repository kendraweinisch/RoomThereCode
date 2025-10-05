import { supabase } from './supabase';

export const contactService = {
  async submitContactForm(formData) {
    const { data, error } = await supabase
      .from('contact_submissions')
      .insert({
        name: formData.name,
        email: formData.email,
        user_type: formData.userType || null,
        subject: formData.subject,
        message: formData.message,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async submitProblemReport(reportData) {
    const { data, error } = await supabase
      .from('problem_reports')
      .insert({
        reporter_name: reportData.name,
        reporter_email: reportData.email,
        issue_type: reportData.issueType,
        subject: reportData.subject,
        description: reportData.description,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  },
};
