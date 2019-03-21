using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace HFO_ENGINE
{
    public partial class Fastwave_conversor : Form
    {
        public Fastwave_conversor()
        {
            InitializeComponent();
        }

        private void SelectEDFbtn_Click(object sender, EventArgs e)
        {
            OpenFileDialog openFileDialog1 = new OpenFileDialog
            {
                Title = "Browse EDF",
                CheckFileExists = true,
                CheckPathExists = true,
                DefaultExt = "edf",
                Filter = "EDF files(*.edf)| *.edf",
                FilterIndex = 2,
                RestoreDirectory = true,
            };
            if (openFileDialog1.ShowDialog() == DialogResult.OK)
            {
                EdfPath_txtBx.Text = openFileDialog1.FileName;
            }
        }

        private void brose_trc_out_dir_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(EdfPath_txtBx.Text))
            {
                MessageBox.Show("Please select an EDF file prior to setting the output saving path.");
            }
            var dialog = new FolderBrowserDialog();
            dialog.ShowDialog();
            Trc_out_conv_dir_txt.Text = dialog.SelectedPath + "\\" + Path.GetFileNameWithoutExtension(EdfPath_txtBx.Text) + ".TRC";
        }

        private void conversor_save_btn_Click(object sender, EventArgs e)
        {
            if (String.IsNullOrEmpty(EdfPath_txtBx.Text) || String.IsNullOrEmpty(Trc_out_conv_dir_txt.Text))
            {
                MessageBox.Show("Please select an EDF file and set the the output saving path.");
            }
            else
            {
                string scriptPath = Program.Scripts_path + "edf_to_trc.py";
                string args = EdfPath_txtBx.Text + " " + Trc_out_conv_dir_txt.Text;
                string script_stream = Program.RunPythonScript(Program.Python_path, scriptPath, args);
            }
        }
    }
}
