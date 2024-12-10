using System.Net.Http;
using System.Text.Json;
using System.Text.Json.Serialization;
using webapi.mode;

var builder = WebApplication.CreateSlimBuilder(args);
builder.WebHost.UseUrls("http://*:8080");
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default);
});

var app = builder.Build();

var sampleTodos = new Todo[] {
    new(1, "Walk the dog"),
    new(2, "Do the dishes", DateOnly.FromDateTime(DateTime.Now)),
    new(3, "Do the laundry", DateOnly.FromDateTime(DateTime.Now.AddDays(1))),
    new(4, "Clean the bathroom"),
    new(5, "Clean the car", DateOnly.FromDateTime(DateTime.Now.AddDays(2)))
};

var todosApi = app.MapGroup("/todos");
todosApi.MapGet("/", () => sampleTodos);
todosApi.MapGet("/AppData", async () => {
    try
    {
        using HttpClient httpClient = new();
        using var response = await httpClient.GetAsync("https://www.cloudflare-cn.com/page-data/app-data.json");
        response.EnsureSuccessStatusCode();
        //var content = await response.Content.ReadAsStringAsync();
        // 读取响应内容并反序列化为 AppData 对象
       var content = await response.Content.ReadFromJsonAsync<AppData>(AppJsonSerializerContext.Default.AppData);
        return Results.Ok(content);
    }
    catch (Exception ex)
    {
        return Results.NoContent();
    }
 


});

todosApi.MapGet("/{id}", (int id) =>
    sampleTodos.FirstOrDefault(a => a.Id == id) is { } todo
        ? Results.Ok(todo)
        : Results.NotFound());

app.Run();

public record Todo(int Id, string? Title, DateOnly? DueBy = null, bool IsComplete = false);

[JsonSerializable(typeof(Todo[]))]
[JsonSerializable(typeof(AppData[]))]
[JsonSerializable(typeof(AppData))]
internal partial class AppJsonSerializerContext : JsonSerializerContext
{

}
