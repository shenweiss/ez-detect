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
    public partial class SSH : Form
    {
        public SSH()
        {
            InitializeComponent();
            try {
                Servername_comboBox.SelectedIndex = Servername_comboBox.Items.IndexOf(Program.ServerName);
            }
            catch (System.IndexOutOfRangeException ex)
            {
                System.ArgumentException argEx = new System.ArgumentException("Index is out of range", "index", ex);
                throw argEx;
            }
            Username_txt.Text = Program.Username;
        }

        private void SSH_save_btn_Click(object sender, EventArgs e)
        {
            Program.ServerName = Servername_comboBox.Text;
            Program.Username = Username_txt.Text;
            Program.Remote_trc_dir = "/home/" + Username_txt.Text + "/TRCs/";
            Program.Remote_evt_dir = "/home/" + Username_txt.Text + "/evts/";
            if (Servername_comboBox.Text == "Grito")
            {
                Program.Hostname = "grito.exp.dc.uba.ar";
            }
            else if (Servername_comboBox.Text == "TJU")
            {
                Program.Hostname = "tju.exp.dc.uba.ar";
            }
            else MessageBox.Show("Unknown Server name.");

        }

    }
}
