using NetFrame.Extensions;
using NetFrame.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

// Register Zosmf Services
builder.Services.AddZosmf(options =>
{
    var zosmfSection = builder.Configuration.GetSection("Zosmf");
    options.BaseUrl = zosmfSection["BaseUrl"] ?? "";
    options.Username = zosmfSection["Username"] ?? "";
    options.Password = zosmfSection["Password"] ?? "";
    options.AllowInsecureConnections = bool.Parse(zosmfSection["AllowInsecureConnections"] ?? "false");
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();
