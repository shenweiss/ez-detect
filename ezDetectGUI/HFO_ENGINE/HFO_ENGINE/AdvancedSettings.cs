using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace HFO_ENGINE
{
    public partial class AdvancedSettings : Form
    {
        public AdvancedSettings()
        {
            InitializeComponent();
            PythonPath_txt.Text = Program.Python_path;
            ScriptsPath_txt.Text = Program.Scripts_path;
            Logfile_txt.Text = Program.Log_file;
            CommandFile_txt.Text = Program.Command_file;
            TrcTemp_txt.Text = Program.TrcTempDir;
        }

        private void AdvancedSettings_save_btn_Click(object sender, EventArgs e)
        {
            Program.Python_path = PythonPath_txt.Text;
            Program.Scripts_path = ScriptsPath_txt.Text;
            Program.Log_file = Logfile_txt.Text;
            Program.Command_file = CommandFile_txt.Text;
            Program.TrcTempDir = TrcTemp_txt.Text;
        }

        private void ScriptsPathLabel_Click(object sender, EventArgs e)
        {

        }

        private void TrcTempDirLabel_Click(object sender, EventArgs e)
        {

        }
    }
}
