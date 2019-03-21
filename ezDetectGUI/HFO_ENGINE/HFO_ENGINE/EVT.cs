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
    public partial class EVT : Form
    {
        public EVT()
        {
            InitializeComponent();
            EvtPath_txtBx.Text = Program.EvtFile;
        }

        private void Evt_save_btn_Click(object sender, EventArgs e)
        {
            Program.EvtFile = EvtPath_txtBx.Text;
        }

        private void exportEVTbtn_Click_1(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(Program.TrcFile))
            {
                MessageBox.Show("Please select a TRC file prior to setting the evt saving path.");
            }
            var dialog = new FolderBrowserDialog();
            dialog.ShowDialog();
            EvtPath_txtBx.Text = dialog.SelectedPath + "\\" + Path.GetFileNameWithoutExtension(Program.TrcFile) + ".evt";
        }
        private void exportEVTbtn_MouseLeave(object sender, EventArgs e)
        {
            exportEVTbtn.Size = new Size(50, 50);
            exportEVTbtn.Location = new Point(150, 50);
        }
        private void exportEVTbtn_MouseEnter(object sender, EventArgs e)
        {
            exportEVTbtn.Size = new Size(60, 60);
            exportEVTbtn.Location = new Point(145, 45);
        }
      
    }
}
