using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Diagnostics;
using System.IO;

namespace HFO_ENGINE
{
    public partial class Montage : Form
    {
     
        public Montage()
        {
            InitializeComponent();
            Load_list(ComboBox_suggested_montage, Program.Montage_names);
            Load_list(ComboBox_bipolar_montage, Program.Montage_names);
            Load_sug_selection();
            Load_bp_selection();

        }

        private void Load_sug_selection() {

            try
            {
                ComboBox_suggested_montage.SelectedIndex = ComboBox_suggested_montage.Items.IndexOf(Program.SuggestedMontage);
            }
            catch (System.IndexOutOfRangeException ex)
            {
                System.ArgumentException argEx = new System.ArgumentException("Index is out of range", "index", ex);
                throw argEx;
            }
        }
        private void Load_bp_selection()
        {

            try
            {
                ComboBox_bipolar_montage.SelectedIndex = ComboBox_bipolar_montage.Items.IndexOf(Program.BpMontage);
            }
            catch (System.IndexOutOfRangeException ex)
            {
                System.ArgumentException argEx = new System.ArgumentException("Index is out of range", "index", ex);
                throw argEx;
            }
        }

        private void Load_list(ComboBox C, string[] list)
        {
            C.Items.AddRange(list);
            
        }
        private void Montage_save_btn_Click(object sender, EventArgs e)
        {
            Program.BpMontage = ComboBox_bipolar_montage.Text;
            Program.SuggestedMontage = ComboBox_suggested_montage.Text;
        }
    }
}
