namespace HFO_ENGINE
{
    partial class MainWindow
    {
        /// <summary>
        /// Variable del diseñador requerida.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Limpiar los recursos que se estén utilizando.
        /// </summary>
        /// <param name="disposing">true si los recursos administrados se deben eliminar; false en caso contrario.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Código generado por el Diseñador de Windows Forms

        /// <summary>
        /// Método necesario para admitir el Diseñador. No se puede modificar
        /// el contenido del método con el editor de código.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MainWindow));
            this.BarraTitulo = new System.Windows.Forms.Panel();
            this.Title = new System.Windows.Forms.Label();
            this.btnRestaurar = new System.Windows.Forms.PictureBox();
            this.btnMinimizar = new System.Windows.Forms.PictureBox();
            this.btnMaximizar = new System.Windows.Forms.PictureBox();
            this.btnCerrar = new System.Windows.Forms.PictureBox();
            this.MenuVertical = new System.Windows.Forms.Panel();
            this.panel8 = new System.Windows.Forms.Panel();
            this.btninicio = new System.Windows.Forms.PictureBox();
            this.panel2 = new System.Windows.Forms.Panel();
            this.panel7 = new System.Windows.Forms.Panel();
            this.BtnAdvancedSettings = new System.Windows.Forms.Button();
            this.panel6 = new System.Windows.Forms.Panel();
            this.BtnOutput = new System.Windows.Forms.Button();
            this.panel5 = new System.Windows.Forms.Panel();
            this.BtnSSH = new System.Windows.Forms.Button();
            this.panel4 = new System.Windows.Forms.Panel();
            this.BtnMultiprocessing = new System.Windows.Forms.Button();
            this.panel3 = new System.Windows.Forms.Panel();
            this.BtnTimeWindow = new System.Windows.Forms.Button();
            this.BtnMontage = new System.Windows.Forms.Button();
            this.panel1 = new System.Windows.Forms.Panel();
            this.BtnEEG = new System.Windows.Forms.Button();
            this.StartBtn = new System.Windows.Forms.Button();
            this.panelContenedor = new System.Windows.Forms.Panel();
            this.BarraTitulo.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.btnRestaurar)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.btnMinimizar)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.btnMaximizar)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.btnCerrar)).BeginInit();
            this.MenuVertical.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.btninicio)).BeginInit();
            this.SuspendLayout();
            // 
            // BarraTitulo
            // 
            this.BarraTitulo.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.BarraTitulo.Controls.Add(this.Title);
            this.BarraTitulo.Controls.Add(this.btnRestaurar);
            this.BarraTitulo.Controls.Add(this.btnMinimizar);
            this.BarraTitulo.Controls.Add(this.btnMaximizar);
            this.BarraTitulo.Controls.Add(this.btnCerrar);
            this.BarraTitulo.Dock = System.Windows.Forms.DockStyle.Top;
            this.BarraTitulo.Location = new System.Drawing.Point(0, 0);
            this.BarraTitulo.Name = "BarraTitulo";
            this.BarraTitulo.Size = new System.Drawing.Size(700, 38);
            this.BarraTitulo.TabIndex = 0;
            this.BarraTitulo.MouseDown += new System.Windows.Forms.MouseEventHandler(this.BarraTitulo_MouseDown);
            // 
            // Title
            // 
            this.Title.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.Title.AutoSize = true;
            this.Title.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Title.Font = new System.Drawing.Font("Franklin Gothic Medium", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Title.ForeColor = System.Drawing.SystemColors.ButtonFace;
            this.Title.Location = new System.Drawing.Point(290, 10);
            this.Title.Name = "Title";
            this.Title.Size = new System.Drawing.Size(104, 24);
            this.Title.TabIndex = 0;
            this.Title.Text = "HFO Engine";
            this.Title.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // btnRestaurar
            // 
            this.btnRestaurar.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnRestaurar.Cursor = System.Windows.Forms.Cursors.Hand;
            this.btnRestaurar.Image = ((System.Drawing.Image)(resources.GetObject("btnRestaurar.Image")));
            this.btnRestaurar.Location = new System.Drawing.Point(621, 6);
            this.btnRestaurar.Name = "btnRestaurar";
            this.btnRestaurar.Size = new System.Drawing.Size(25, 25);
            this.btnRestaurar.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.btnRestaurar.TabIndex = 3;
            this.btnRestaurar.TabStop = false;
            this.btnRestaurar.Visible = false;
            this.btnRestaurar.Click += new System.EventHandler(this.btnRestaurar_Click);
            // 
            // btnMinimizar
            // 
            this.btnMinimizar.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnMinimizar.Cursor = System.Windows.Forms.Cursors.Hand;
            this.btnMinimizar.Image = ((System.Drawing.Image)(resources.GetObject("btnMinimizar.Image")));
            this.btnMinimizar.Location = new System.Drawing.Point(580, 6);
            this.btnMinimizar.Name = "btnMinimizar";
            this.btnMinimizar.Size = new System.Drawing.Size(25, 25);
            this.btnMinimizar.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.btnMinimizar.TabIndex = 2;
            this.btnMinimizar.TabStop = false;
            this.btnMinimizar.Click += new System.EventHandler(this.btnMinimizar_Click);
            // 
            // btnMaximizar
            // 
            this.btnMaximizar.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnMaximizar.Cursor = System.Windows.Forms.Cursors.Hand;
            this.btnMaximizar.Image = ((System.Drawing.Image)(resources.GetObject("btnMaximizar.Image")));
            this.btnMaximizar.Location = new System.Drawing.Point(621, 6);
            this.btnMaximizar.Name = "btnMaximizar";
            this.btnMaximizar.Size = new System.Drawing.Size(25, 25);
            this.btnMaximizar.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.btnMaximizar.TabIndex = 1;
            this.btnMaximizar.TabStop = false;
            this.btnMaximizar.Click += new System.EventHandler(this.btnMaximizar_Click);
            // 
            // btnCerrar
            // 
            this.btnCerrar.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnCerrar.Cursor = System.Windows.Forms.Cursors.Hand;
            this.btnCerrar.Image = ((System.Drawing.Image)(resources.GetObject("btnCerrar.Image")));
            this.btnCerrar.Location = new System.Drawing.Point(662, 6);
            this.btnCerrar.Name = "btnCerrar";
            this.btnCerrar.Size = new System.Drawing.Size(25, 25);
            this.btnCerrar.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.btnCerrar.TabIndex = 0;
            this.btnCerrar.TabStop = false;
            this.btnCerrar.Click += new System.EventHandler(this.btnCerrar_Click);
            // 
            // MenuVertical
            // 
            this.MenuVertical.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(32)))), ((int)(((byte)(40)))));
            this.MenuVertical.Controls.Add(this.panel8);
            this.MenuVertical.Controls.Add(this.btninicio);
            this.MenuVertical.Controls.Add(this.panel2);
            this.MenuVertical.Controls.Add(this.panel7);
            this.MenuVertical.Controls.Add(this.BtnAdvancedSettings);
            this.MenuVertical.Controls.Add(this.panel6);
            this.MenuVertical.Controls.Add(this.BtnOutput);
            this.MenuVertical.Controls.Add(this.panel5);
            this.MenuVertical.Controls.Add(this.BtnSSH);
            this.MenuVertical.Controls.Add(this.panel4);
            this.MenuVertical.Controls.Add(this.BtnMultiprocessing);
            this.MenuVertical.Controls.Add(this.panel3);
            this.MenuVertical.Controls.Add(this.BtnTimeWindow);
            this.MenuVertical.Controls.Add(this.BtnMontage);
            this.MenuVertical.Controls.Add(this.panel1);
            this.MenuVertical.Controls.Add(this.BtnEEG);
            this.MenuVertical.Controls.Add(this.StartBtn);
            this.MenuVertical.Dock = System.Windows.Forms.DockStyle.Left;
            this.MenuVertical.Location = new System.Drawing.Point(0, 38);
            this.MenuVertical.Name = "MenuVertical";
            this.MenuVertical.Size = new System.Drawing.Size(220, 512);
            this.MenuVertical.TabIndex = 1;
            // 
            // panel8
            // 
            this.panel8.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.panel8.Location = new System.Drawing.Point(0, 427);
            this.panel8.Name = "panel8";
            this.panel8.Size = new System.Drawing.Size(5, 73);
            this.panel8.TabIndex = 15;
            // 
            // btninicio
            // 
            this.btninicio.Cursor = System.Windows.Forms.Cursors.Hand;
            this.btninicio.Image = ((System.Drawing.Image)(resources.GetObject("btninicio.Image")));
            this.btninicio.Location = new System.Drawing.Point(0, 0);
            this.btninicio.Name = "btninicio";
            this.btninicio.Size = new System.Drawing.Size(220, 80);
            this.btninicio.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.btninicio.TabIndex = 0;
            this.btninicio.TabStop = false;
            // 
            // panel2
            // 
            this.panel2.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.panel2.Location = new System.Drawing.Point(0, 280);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(5, 40);
            this.panel2.TabIndex = 4;
            // 
            // panel7
            // 
            this.panel7.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.panel7.Location = new System.Drawing.Point(0, 370);
            this.panel7.Name = "panel7";
            this.panel7.Size = new System.Drawing.Size(5, 40);
            this.panel7.TabIndex = 14;
            // 
            // BtnAdvancedSettings
            // 
            this.BtnAdvancedSettings.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(32)))), ((int)(((byte)(40)))));
            this.BtnAdvancedSettings.FlatAppearance.BorderSize = 0;
            this.BtnAdvancedSettings.FlatAppearance.MouseOverBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.BtnAdvancedSettings.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.BtnAdvancedSettings.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.BtnAdvancedSettings.ForeColor = System.Drawing.Color.White;
            this.BtnAdvancedSettings.Image = ((System.Drawing.Image)(resources.GetObject("BtnAdvancedSettings.Image")));
            this.BtnAdvancedSettings.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.BtnAdvancedSettings.Location = new System.Drawing.Point(17, 370);
            this.BtnAdvancedSettings.Name = "BtnAdvancedSettings";
            this.BtnAdvancedSettings.Size = new System.Drawing.Size(203, 40);
            this.BtnAdvancedSettings.TabIndex = 13;
            this.BtnAdvancedSettings.Text = "      Advanced settings";
            this.BtnAdvancedSettings.UseVisualStyleBackColor = false;
            this.BtnAdvancedSettings.Click += new System.EventHandler(this.BtnAdvancedSettings_Click);
            // 
            // panel6
            // 
            this.panel6.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.panel6.Location = new System.Drawing.Point(0, 325);
            this.panel6.Name = "panel6";
            this.panel6.Size = new System.Drawing.Size(5, 40);
            this.panel6.TabIndex = 12;
            // 
            // BtnOutput
            // 
            this.BtnOutput.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(32)))), ((int)(((byte)(40)))));
            this.BtnOutput.FlatAppearance.BorderSize = 0;
            this.BtnOutput.FlatAppearance.MouseOverBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.BtnOutput.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.BtnOutput.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.BtnOutput.ForeColor = System.Drawing.Color.White;
            this.BtnOutput.Image = ((System.Drawing.Image)(resources.GetObject("BtnOutput.Image")));
            this.BtnOutput.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.BtnOutput.Location = new System.Drawing.Point(15, 325);
            this.BtnOutput.Name = "BtnOutput";
            this.BtnOutput.Size = new System.Drawing.Size(205, 40);
            this.BtnOutput.TabIndex = 11;
            this.BtnOutput.Text = "Output";
            this.BtnOutput.UseVisualStyleBackColor = false;
            this.BtnOutput.Click += new System.EventHandler(this.BtnOutput_Click);
            // 
            // panel5
            // 
            this.panel5.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.panel5.Location = new System.Drawing.Point(0, 235);
            this.panel5.Name = "panel5";
            this.panel5.Size = new System.Drawing.Size(5, 40);
            this.panel5.TabIndex = 10;
            // 
            // BtnSSH
            // 
            this.BtnSSH.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(32)))), ((int)(((byte)(40)))));
            this.BtnSSH.FlatAppearance.BorderSize = 0;
            this.BtnSSH.FlatAppearance.MouseOverBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.BtnSSH.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.BtnSSH.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.BtnSSH.ForeColor = System.Drawing.Color.White;
            this.BtnSSH.Image = ((System.Drawing.Image)(resources.GetObject("BtnSSH.Image")));
            this.BtnSSH.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.BtnSSH.Location = new System.Drawing.Point(15, 280);
            this.BtnSSH.Name = "BtnSSH";
            this.BtnSSH.Size = new System.Drawing.Size(205, 40);
            this.BtnSSH.TabIndex = 9;
            this.BtnSSH.Text = "SSH";
            this.BtnSSH.UseVisualStyleBackColor = false;
            this.BtnSSH.Click += new System.EventHandler(this.BtnSSH_Click);
            // 
            // panel4
            // 
            this.panel4.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.panel4.Location = new System.Drawing.Point(0, 190);
            this.panel4.Name = "panel4";
            this.panel4.Size = new System.Drawing.Size(5, 40);
            this.panel4.TabIndex = 8;
            // 
            // BtnMultiprocessing
            // 
            this.BtnMultiprocessing.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(32)))), ((int)(((byte)(40)))));
            this.BtnMultiprocessing.FlatAppearance.BorderSize = 0;
            this.BtnMultiprocessing.FlatAppearance.MouseOverBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.BtnMultiprocessing.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.BtnMultiprocessing.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.BtnMultiprocessing.ForeColor = System.Drawing.Color.White;
            this.BtnMultiprocessing.Image = ((System.Drawing.Image)(resources.GetObject("BtnMultiprocessing.Image")));
            this.BtnMultiprocessing.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.BtnMultiprocessing.Location = new System.Drawing.Point(15, 235);
            this.BtnMultiprocessing.Name = "BtnMultiprocessing";
            this.BtnMultiprocessing.Size = new System.Drawing.Size(205, 40);
            this.BtnMultiprocessing.TabIndex = 7;
            this.BtnMultiprocessing.Text = "Multiprocessing";
            this.BtnMultiprocessing.UseVisualStyleBackColor = false;
            this.BtnMultiprocessing.Click += new System.EventHandler(this.BtnMultiprocessing_Click);
            // 
            // panel3
            // 
            this.panel3.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.panel3.Location = new System.Drawing.Point(0, 145);
            this.panel3.Name = "panel3";
            this.panel3.Size = new System.Drawing.Size(5, 40);
            this.panel3.TabIndex = 6;
            // 
            // BtnTimeWindow
            // 
            this.BtnTimeWindow.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(32)))), ((int)(((byte)(40)))));
            this.BtnTimeWindow.FlatAppearance.BorderSize = 0;
            this.BtnTimeWindow.FlatAppearance.MouseOverBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.BtnTimeWindow.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.BtnTimeWindow.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.BtnTimeWindow.ForeColor = System.Drawing.Color.White;
            this.BtnTimeWindow.Image = ((System.Drawing.Image)(resources.GetObject("BtnTimeWindow.Image")));
            this.BtnTimeWindow.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.BtnTimeWindow.Location = new System.Drawing.Point(17, 190);
            this.BtnTimeWindow.Name = "BtnTimeWindow";
            this.BtnTimeWindow.Size = new System.Drawing.Size(203, 40);
            this.BtnTimeWindow.TabIndex = 5;
            this.BtnTimeWindow.Text = "Time-window";
            this.BtnTimeWindow.UseVisualStyleBackColor = false;
            this.BtnTimeWindow.Click += new System.EventHandler(this.BtnTimeWindow_Click);
            // 
            // BtnMontage
            // 
            this.BtnMontage.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(32)))), ((int)(((byte)(40)))));
            this.BtnMontage.FlatAppearance.BorderSize = 0;
            this.BtnMontage.FlatAppearance.MouseOverBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.BtnMontage.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.BtnMontage.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.BtnMontage.ForeColor = System.Drawing.Color.White;
            this.BtnMontage.Image = ((System.Drawing.Image)(resources.GetObject("BtnMontage.Image")));
            this.BtnMontage.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.BtnMontage.Location = new System.Drawing.Point(15, 145);
            this.BtnMontage.Name = "BtnMontage";
            this.BtnMontage.Size = new System.Drawing.Size(205, 40);
            this.BtnMontage.TabIndex = 3;
            this.BtnMontage.Text = "Montage";
            this.BtnMontage.UseVisualStyleBackColor = false;
            this.BtnMontage.Click += new System.EventHandler(this.BtnMontage_Click);
            // 
            // panel1
            // 
            this.panel1.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.panel1.Location = new System.Drawing.Point(0, 100);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(5, 40);
            this.panel1.TabIndex = 2;
            // 
            // BtnEEG
            // 
            this.BtnEEG.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(32)))), ((int)(((byte)(40)))));
            this.BtnEEG.Cursor = System.Windows.Forms.Cursors.Hand;
            this.BtnEEG.FlatAppearance.BorderSize = 0;
            this.BtnEEG.FlatAppearance.MouseOverBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(80)))), ((int)(((byte)(200)))));
            this.BtnEEG.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.BtnEEG.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.BtnEEG.ForeColor = System.Drawing.Color.White;
            this.BtnEEG.Image = ((System.Drawing.Image)(resources.GetObject("BtnEEG.Image")));
            this.BtnEEG.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.BtnEEG.Location = new System.Drawing.Point(15, 100);
            this.BtnEEG.Name = "BtnEEG";
            this.BtnEEG.Size = new System.Drawing.Size(205, 40);
            this.BtnEEG.TabIndex = 1;
            this.BtnEEG.Text = "EEG";
            this.BtnEEG.UseVisualStyleBackColor = false;
            this.BtnEEG.Click += new System.EventHandler(this.BtnEEG_Click);
            // 
            // StartBtn
            // 
            this.StartBtn.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(32)))), ((int)(((byte)(40)))));
            this.StartBtn.FlatAppearance.BorderSize = 0;
            this.StartBtn.FlatAppearance.MouseOverBackColor = System.Drawing.Color.DarkGreen;
            this.StartBtn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.StartBtn.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.StartBtn.ForeColor = System.Drawing.Color.White;
            this.StartBtn.Image = ((System.Drawing.Image)(resources.GetObject("StartBtn.Image")));
            this.StartBtn.Location = new System.Drawing.Point(3, 427);
            this.StartBtn.Name = "StartBtn";
            this.StartBtn.Size = new System.Drawing.Size(214, 73);
            this.StartBtn.TabIndex = 16;
            this.StartBtn.UseVisualStyleBackColor = false;
            this.StartBtn.Click += new System.EventHandler(this.StartBtn_Click);
            // 
            // panelContenedor
            // 
            this.panelContenedor.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.panelContenedor.Dock = System.Windows.Forms.DockStyle.Fill;
            this.panelContenedor.Location = new System.Drawing.Point(220, 38);
            this.panelContenedor.Name = "panelContenedor";
            this.panelContenedor.Size = new System.Drawing.Size(480, 512);
            this.panelContenedor.TabIndex = 2;
            // 
            // MainWindow
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(700, 550);
            this.Controls.Add(this.panelContenedor);
            this.Controls.Add(this.MenuVertical);
            this.Controls.Add(this.BarraTitulo);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.Name = "MainWindow";
            this.Text = "Form1";
            this.BarraTitulo.ResumeLayout(false);
            this.BarraTitulo.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.btnRestaurar)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.btnMinimizar)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.btnMaximizar)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.btnCerrar)).EndInit();
            this.MenuVertical.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.btninicio)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Panel BarraTitulo;
        private System.Windows.Forms.PictureBox btnCerrar;
        private System.Windows.Forms.Panel MenuVertical;
        private System.Windows.Forms.Panel panelContenedor;
        private System.Windows.Forms.PictureBox btnRestaurar;
        private System.Windows.Forms.PictureBox btnMinimizar;
        private System.Windows.Forms.PictureBox btnMaximizar;
        private System.Windows.Forms.Button BtnEEG;
        private System.Windows.Forms.PictureBox btninicio;
        private System.Windows.Forms.Panel panel1;
        private System.Windows.Forms.Panel panel7;
        private System.Windows.Forms.Button BtnAdvancedSettings;
        private System.Windows.Forms.Panel panel6;
        private System.Windows.Forms.Button BtnOutput;
        private System.Windows.Forms.Panel panel5;
        private System.Windows.Forms.Button BtnSSH;
        private System.Windows.Forms.Panel panel4;
        private System.Windows.Forms.Button BtnMultiprocessing;
        private System.Windows.Forms.Panel panel3;
        private System.Windows.Forms.Button BtnTimeWindow;
        private System.Windows.Forms.Panel panel2;
        private System.Windows.Forms.Button BtnMontage;
        private System.Windows.Forms.Button StartBtn;
        private System.Windows.Forms.Panel panel8;
        private System.Windows.Forms.Label Title;
    }
}

