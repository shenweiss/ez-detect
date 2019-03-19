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
    public partial class EEG : Form
    {
        public EEG()
        {
            InitializeComponent();
            TrcPath_txtBx.Text = Program.TrcFile;
        }

        private void ImportTRCbtn_Click(object sender, EventArgs e)
        {
            OpenFileDialog openFileDialog1 = new OpenFileDialog
            {
                Title = "Browse TRC",
                CheckFileExists = true,
                CheckPathExists = true,
                DefaultExt = "TRC",
                Filter = "TRC files(*.TRC)| *.TRC",
                FilterIndex = 2,
                RestoreDirectory = true,
            };
            if (openFileDialog1.ShowDialog() == DialogResult.OK)
            {
                TrcPath_txtBx.Text = openFileDialog1.FileName;
            }
        }

        private void EEG_save_btn_Click(object sender, EventArgs e)
        {
            Program.TrcFile = (string)this.TrcPath_txtBx.Text;
            Program.load_trc_data();
        }

    }
}
