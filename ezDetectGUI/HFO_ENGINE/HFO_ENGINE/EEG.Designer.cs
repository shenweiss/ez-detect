namespace HFO_ENGINE
{
    partial class EEG
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(EEG));
            this.trcImportLabel = new System.Windows.Forms.Label();
            this.TrcPath_txtBx = new System.Windows.Forms.TextBox();
            this.EEG_title = new System.Windows.Forms.Label();
            this.EEG_save_btn = new System.Windows.Forms.Button();
            this.panel2 = new System.Windows.Forms.Panel();
            this.importTRCbtn = new System.Windows.Forms.PictureBox();
            this.line = new System.Windows.Forms.Label();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.panel1 = new System.Windows.Forms.Panel();
            this.panel2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.importTRCbtn)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.panel1.SuspendLayout();
            this.SuspendLayout();
            // 
            // trcImportLabel
            // 
            this.trcImportLabel.BackColor = System.Drawing.Color.Transparent;
            this.trcImportLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.trcImportLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.trcImportLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.trcImportLabel.Location = new System.Drawing.Point(0, 0);
            this.trcImportLabel.Name = "trcImportLabel";
            this.trcImportLabel.Size = new System.Drawing.Size(140, 26);
            this.trcImportLabel.TabIndex = 1;
            this.trcImportLabel.Text = "Import TRC file";
            // 
            // TrcPath_txtBx
            // 
            this.TrcPath_txtBx.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.TrcPath_txtBx.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.TrcPath_txtBx.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.TrcPath_txtBx.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F);
            this.TrcPath_txtBx.ForeColor = System.Drawing.SystemColors.Window;
            this.TrcPath_txtBx.Location = new System.Drawing.Point(8, 150);
            this.TrcPath_txtBx.Name = "TrcPath_txtBx";
            this.TrcPath_txtBx.ScrollBars = System.Windows.Forms.ScrollBars.Horizontal;
            this.TrcPath_txtBx.Size = new System.Drawing.Size(350, 17);
            this.TrcPath_txtBx.TabIndex = 2;
            this.TrcPath_txtBx.UseWaitCursor = true;
            // 
            // EEG_title
            // 
            this.EEG_title.BackColor = System.Drawing.Color.Transparent;
            this.EEG_title.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.EEG_title.Font = new System.Drawing.Font("Arial", 18F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.EEG_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.EEG_title.Location = new System.Drawing.Point(-3, 0);
            this.EEG_title.Name = "EEG_title";
            this.EEG_title.Size = new System.Drawing.Size(148, 37);
            this.EEG_title.TabIndex = 4;
            this.EEG_title.Text = "Data source";
            // 
            // EEG_save_btn
            // 
            this.EEG_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.EEG_save_btn.FlatAppearance.BorderSize = 2;
            this.EEG_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.EEG_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold);
            this.EEG_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.EEG_save_btn.Location = new System.Drawing.Point(278, 286);
            this.EEG_save_btn.Name = "EEG_save_btn";
            this.EEG_save_btn.Size = new System.Drawing.Size(82, 34);
            this.EEG_save_btn.TabIndex = 5;
            this.EEG_save_btn.Text = "Save";
            this.EEG_save_btn.UseVisualStyleBackColor = true;
            // 
            // panel2
            // 
            this.panel2.Controls.Add(this.importTRCbtn);
            this.panel2.Controls.Add(this.line);
            this.panel2.Controls.Add(this.trcImportLabel);
            this.panel2.Controls.Add(this.EEG_save_btn);
            this.panel2.Controls.Add(this.TrcPath_txtBx);
            this.panel2.Location = new System.Drawing.Point(55, 150);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(360, 320);
            this.panel2.TabIndex = 9;
            // 
            // importTRCbtn
            // 
            this.importTRCbtn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.importTRCbtn.Image = ((System.Drawing.Image)(resources.GetObject("importTRCbtn.Image")));
            this.importTRCbtn.InitialImage = ((System.Drawing.Image)(resources.GetObject("importTRCbtn.InitialImage")));
            this.importTRCbtn.Location = new System.Drawing.Point(150, 50);
            this.importTRCbtn.Name = "importTRCbtn";
            this.importTRCbtn.Size = new System.Drawing.Size(50, 50);
            this.importTRCbtn.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.importTRCbtn.TabIndex = 8;
            this.importTRCbtn.TabStop = false;
            this.importTRCbtn.Click += new System.EventHandler(this.importBtn_Click);
            this.importTRCbtn.MouseEnter += new System.EventHandler(this.importTRCbtn_MouseEnter);
            this.importTRCbtn.MouseLeave += new System.EventHandler(this.importTRCbtn_MouseLeave);
            // 
            // line
            // 
            this.line.BackColor = System.Drawing.Color.White;
            this.line.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.line.Location = new System.Drawing.Point(8, 175);
            this.line.Name = "line";
            this.line.Size = new System.Drawing.Size(350, 2);
            this.line.TabIndex = 6;
            // 
            // pictureBox1
            // 
            this.pictureBox1.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.pictureBox1.Image = ((System.Drawing.Image)(resources.GetObject("pictureBox1.Image")));
            this.pictureBox1.InitialImage = null;
            this.pictureBox1.Location = new System.Drawing.Point(270, 0);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(95, 95);
            this.pictureBox1.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.pictureBox1.TabIndex = 9;
            this.pictureBox1.TabStop = false;
            // 
            // panel1
            // 
            this.panel1.Controls.Add(this.EEG_title);
            this.panel1.Controls.Add(this.pictureBox1);
            this.panel1.Location = new System.Drawing.Point(50, 55);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(365, 95);
            this.panel1.TabIndex = 10;
            // 
            // EEG
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.AutoSize = true;
            this.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.panel2);
            this.Controls.Add(this.panel1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "EEG";
            this.Text = "EEG";
            this.panel2.ResumeLayout(false);
            this.panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.importTRCbtn)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.panel1.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Label trcImportLabel;
        private System.Windows.Forms.Label EEG_title;
        private System.Windows.Forms.Button EEG_save_btn;
        private System.Windows.Forms.Panel panel2;
        private System.Windows.Forms.TextBox TrcPath_txtBx;
        private System.Windows.Forms.Label line;
        private System.Windows.Forms.PictureBox importTRCbtn;
        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.Panel panel1;
    }
}