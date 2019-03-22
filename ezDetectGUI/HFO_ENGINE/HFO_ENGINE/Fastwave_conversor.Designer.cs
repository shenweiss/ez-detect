namespace HFO_ENGINE
{
    partial class Fastwave_conversor
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Fastwave_conversor));
            this.panel1 = new System.Windows.Forms.Panel();
            this.browse_trc_out_dir = new System.Windows.Forms.PictureBox();
            this.Trc_out_conv_dir_txt = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.SavingConvTrcDir = new System.Windows.Forms.Label();
            this.EdfPath_txtBx = new System.Windows.Forms.TextBox();
            this.SelectEDFbtn = new System.Windows.Forms.PictureBox();
            this.line = new System.Windows.Forms.Label();
            this.edf_import_label = new System.Windows.Forms.Label();
            this.conversor_save_btn = new System.Windows.Forms.Button();
            this.panel4 = new System.Windows.Forms.Panel();
            this.Convert_title = new System.Windows.Forms.Label();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.panel1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.browse_trc_out_dir)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.SelectEDFbtn)).BeginInit();
            this.panel4.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.SuspendLayout();
            // 
            // panel1
            // 
            this.panel1.Controls.Add(this.browse_trc_out_dir);
            this.panel1.Controls.Add(this.Trc_out_conv_dir_txt);
            this.panel1.Controls.Add(this.label1);
            this.panel1.Controls.Add(this.SavingConvTrcDir);
            this.panel1.Controls.Add(this.EdfPath_txtBx);
            this.panel1.Controls.Add(this.SelectEDFbtn);
            this.panel1.Controls.Add(this.line);
            this.panel1.Controls.Add(this.edf_import_label);
            this.panel1.Controls.Add(this.conversor_save_btn);
            this.panel1.Location = new System.Drawing.Point(60, 166);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(360, 320);
            this.panel1.TabIndex = 34;
            // 
            // browse_trc_out_dir
            // 
            this.browse_trc_out_dir.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.browse_trc_out_dir.Image = ((System.Drawing.Image)(resources.GetObject("browse_trc_out_dir.Image")));
            this.browse_trc_out_dir.InitialImage = ((System.Drawing.Image)(resources.GetObject("browse_trc_out_dir.InitialImage")));
            this.browse_trc_out_dir.Location = new System.Drawing.Point(260, 180);
            this.browse_trc_out_dir.Name = "browse_trc_out_dir";
            this.browse_trc_out_dir.Size = new System.Drawing.Size(50, 50);
            this.browse_trc_out_dir.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.browse_trc_out_dir.TabIndex = 36;
            this.browse_trc_out_dir.TabStop = false;
            this.browse_trc_out_dir.Click += new System.EventHandler(this.brose_trc_out_dir_Click);
            // 
            // Trc_out_conv_dir_txt
            // 
            this.Trc_out_conv_dir_txt.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.Trc_out_conv_dir_txt.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.Trc_out_conv_dir_txt.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.Trc_out_conv_dir_txt.Cursor = System.Windows.Forms.Cursors.IBeam;
            this.Trc_out_conv_dir_txt.Enabled = false;
            this.Trc_out_conv_dir_txt.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F);
            this.Trc_out_conv_dir_txt.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Trc_out_conv_dir_txt.HideSelection = false;
            this.Trc_out_conv_dir_txt.Location = new System.Drawing.Point(0, 236);
            this.Trc_out_conv_dir_txt.Name = "Trc_out_conv_dir_txt";
            this.Trc_out_conv_dir_txt.ScrollBars = System.Windows.Forms.ScrollBars.Horizontal;
            this.Trc_out_conv_dir_txt.Size = new System.Drawing.Size(350, 17);
            this.Trc_out_conv_dir_txt.TabIndex = 35;
            // 
            // label1
            // 
            this.label1.BackColor = System.Drawing.Color.White;
            this.label1.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label1.Location = new System.Drawing.Point(0, 261);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(350, 2);
            this.label1.TabIndex = 34;
            // 
            // SavingConvTrcDir
            // 
            this.SavingConvTrcDir.BackColor = System.Drawing.Color.Transparent;
            this.SavingConvTrcDir.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.SavingConvTrcDir.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.SavingConvTrcDir.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.SavingConvTrcDir.Location = new System.Drawing.Point(-4, 139);
            this.SavingConvTrcDir.Name = "SavingConvTrcDir";
            this.SavingConvTrcDir.Size = new System.Drawing.Size(266, 26);
            this.SavingConvTrcDir.TabIndex = 33;
            this.SavingConvTrcDir.Text = "Pick the output TRC saving directory";
            // 
            // EdfPath_txtBx
            // 
            this.EdfPath_txtBx.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.EdfPath_txtBx.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.EdfPath_txtBx.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.EdfPath_txtBx.Cursor = System.Windows.Forms.Cursors.IBeam;
            this.EdfPath_txtBx.Enabled = false;
            this.EdfPath_txtBx.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F);
            this.EdfPath_txtBx.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.EdfPath_txtBx.HideSelection = false;
            this.EdfPath_txtBx.Location = new System.Drawing.Point(0, 87);
            this.EdfPath_txtBx.Name = "EdfPath_txtBx";
            this.EdfPath_txtBx.ScrollBars = System.Windows.Forms.ScrollBars.Horizontal;
            this.EdfPath_txtBx.Size = new System.Drawing.Size(350, 17);
            this.EdfPath_txtBx.TabIndex = 32;
            // 
            // SelectEDFbtn
            // 
            this.SelectEDFbtn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.SelectEDFbtn.Image = ((System.Drawing.Image)(resources.GetObject("SelectEDFbtn.Image")));
            this.SelectEDFbtn.InitialImage = ((System.Drawing.Image)(resources.GetObject("SelectEDFbtn.InitialImage")));
            this.SelectEDFbtn.Location = new System.Drawing.Point(260, 31);
            this.SelectEDFbtn.Name = "SelectEDFbtn";
            this.SelectEDFbtn.Size = new System.Drawing.Size(50, 50);
            this.SelectEDFbtn.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.SelectEDFbtn.TabIndex = 31;
            this.SelectEDFbtn.TabStop = false;
            this.SelectEDFbtn.Click += new System.EventHandler(this.SelectEDFbtn_Click);
            // 
            // line
            // 
            this.line.BackColor = System.Drawing.Color.White;
            this.line.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.line.Location = new System.Drawing.Point(0, 112);
            this.line.Name = "line";
            this.line.Size = new System.Drawing.Size(350, 2);
            this.line.TabIndex = 30;
            // 
            // edf_import_label
            // 
            this.edf_import_label.BackColor = System.Drawing.Color.Transparent;
            this.edf_import_label.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.edf_import_label.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.edf_import_label.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.edf_import_label.Location = new System.Drawing.Point(2, 6);
            this.edf_import_label.Name = "edf_import_label";
            this.edf_import_label.Size = new System.Drawing.Size(208, 26);
            this.edf_import_label.TabIndex = 29;
            this.edf_import_label.Text = "Browse edf file to convert";
            // 
            // conversor_save_btn
            // 
            this.conversor_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.conversor_save_btn.FlatAppearance.BorderSize = 2;
            this.conversor_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.conversor_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold);
            this.conversor_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.conversor_save_btn.Location = new System.Drawing.Point(260, 286);
            this.conversor_save_btn.Name = "conversor_save_btn";
            this.conversor_save_btn.Size = new System.Drawing.Size(100, 34);
            this.conversor_save_btn.TabIndex = 28;
            this.conversor_save_btn.Text = "Convert";
            this.conversor_save_btn.UseVisualStyleBackColor = true;
            this.conversor_save_btn.Click += new System.EventHandler(this.conversor_save_btn_Click);
            // 
            // panel4
            // 
            this.panel4.Controls.Add(this.Convert_title);
            this.panel4.Controls.Add(this.pictureBox1);
            this.panel4.Location = new System.Drawing.Point(30, 50);
            this.panel4.Name = "panel4";
            this.panel4.Size = new System.Drawing.Size(390, 95);
            this.panel4.TabIndex = 35;
            // 
            // Convert_title
            // 
            this.Convert_title.Font = new System.Drawing.Font("Arial", 22F);
            this.Convert_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Convert_title.Location = new System.Drawing.Point(-5, 0);
            this.Convert_title.Name = "Convert_title";
            this.Convert_title.Size = new System.Drawing.Size(269, 40);
            this.Convert_title.TabIndex = 29;
            this.Convert_title.Text = "EDF to TRC";
            // 
            // pictureBox1
            // 
            this.pictureBox1.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.pictureBox1.Image = ((System.Drawing.Image)(resources.GetObject("pictureBox1.Image")));
            this.pictureBox1.InitialImage = null;
            this.pictureBox1.Location = new System.Drawing.Point(295, 0);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(95, 95);
            this.pictureBox1.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.pictureBox1.TabIndex = 9;
            this.pictureBox1.TabStop = false;
            // 
            // Fastwave_conversor
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.panel1);
            this.Controls.Add(this.panel4);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "Fastwave_conversor";
            this.Text = "Fastwave_conversor";
            this.panel1.ResumeLayout(false);
            this.panel1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.browse_trc_out_dir)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.SelectEDFbtn)).EndInit();
            this.panel4.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Panel panel1;
        private System.Windows.Forms.PictureBox browse_trc_out_dir;
        private System.Windows.Forms.TextBox Trc_out_conv_dir_txt;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label SavingConvTrcDir;
        private System.Windows.Forms.TextBox EdfPath_txtBx;
        private System.Windows.Forms.PictureBox SelectEDFbtn;
        private System.Windows.Forms.Label line;
        private System.Windows.Forms.Label edf_import_label;
        private System.Windows.Forms.Button conversor_save_btn;
        private System.Windows.Forms.Panel panel4;
        private System.Windows.Forms.Label Convert_title;
        private System.Windows.Forms.PictureBox pictureBox1;
    }
}